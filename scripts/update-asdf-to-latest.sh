#!/bin/bash


# Check dependencies
expected="git semver asdf"
for expect in $expected; do
    if ! command -v $expect > /dev/null; then
    echo "Missing dependency: $expect"
    exit 1
    fi
done

echo "This action will grab the latest versions for each tool listed in the .tool-versions file"
echo "Check environment variables are set..."
REPO_EMAIL="${REPO_EMAIL:-github-actions@github.com}"
REPO_USER="${REPO_USER:-github-actions}"
expected="GIT_TOKEN REPO_OWNER REPO_NAME REPO_EMAIL REPO_USER REPO_BRANCH"
for expect in $expected; do
  if [[ -z "${!expect}" ]]; then
    echo "Missing Github Secret: $expect"
    exit 1
  fi
done

# Get the current version of the repo using asdf
rm -rf ${REPO_NAME}
git clone https://${GIT_TOKEN}:x-oauth-basic@github.com/${REPO_OWNER}/${REPO_NAME}.git
pushd ${REPO_NAME}

# Check for required files
if ! [[ -f .tool-versions ]]; then
  echo "Missing .tool-versions file"
  exit 1
fi
cp .tool-versions .tool-versions-orig

# Set the user to allow the script to push to Github
git config --global user.email "${REPO_EMAIL}"
git config --global user.name "${REPO_USER}"

echo "Ensure host has plugins installed to grab latest versions"
while IFS= read -r line; do 
  dep=$(echo "$line" | awk '{print $1}')
  asdf plugin add $dep
done < .tool-versions
touch pin
touch updated
while IFS= read -r line; do
  dep=$(echo "$line" | awk '{print $1}')
  installed=$(echo "$line" | awk '{print $2}')
  echo "----------------------"
  echo "Current Version: $dep $installed"
  latest=$(asdf latest $dep)
  echo " Latest Version: $dep $latest"
  if [[ -z "$latest" ]]; then
    echo "Could not get latest version for $dep. Pinning to $installed"
    echo "$dep $installed" >> updated
  fi
  if [[ -z "$(cat updated | grep "$dep ")" ]]; then
    if [[ -z "$(cat pin | grep "$dep ")" ]]; then
      if [[ "$installed" =~ "$latest" ]]; then
        echo "$dep already at latest $latest"
        echo "$dep $installed" >> updated
      else
        echo "Updating $dep from $installed to $latest"
        echo "$dep $latest" >> updated
      fi
    else
      pinned=$(cat pin | grep "$dep ")
      echo "Pinned versions:"
      echo "$pinned"
      echo "$pinned" >> updated
    fi
  fi
done < .tool-versions
cat updated | sort | uniq > .tool-versions
rm -rf updated
echo "--------------------------"
echo "To apply run: asdf install"
echo "--------------------------"

# In case semver was updated, set the current global version to the newest version
asdf global semver latest
# If diff returns a result, there are updates that need to be pushed
if [[ -n "$(diff .tool-versions .tool-versions-orig)" ]]; then
  rm -rf .tool-versions-orig
  git status
  currentTag=$(git describe --tags | sed -e 's/-.*//g')
  newTag=$(semver bump patch $currentTag)
  if [[ -z "${newTag}" ]]; then
    echo "Could not bump new semver from: ${currentTag}"
    exit 1
  fi
  git add .tool-versions
  git commit -m "Get new dependency versions (asdf)"
  git push origin $REPO_BRANCH
  git tag "v${newTag}"
  git push origin "v${newTag}"
else
  echo "There were no updates to asdf dependencies. Do nothing."
fi
popd
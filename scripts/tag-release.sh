#!/bin/bash

echo "Tag release, multi-arch-build and push"
# Check dependencies
expected="curl docker git jq"
for expect in $expected; do
    if ! command -v $expect > /dev/null; then
    echo "Missing dependency: $expect"
    exit 1
    fi
done

echo "Check environment variables are set..."
expected="REGISTRY_USERNAME REGISTRY_PASSWORD REGISTRY_URL REGISTRY_APPNAME GIT_TOKEN REPO_OWNER REPO_NAME REPO_BRANCH"
for expect in $expected; do
  if [[ -z "${!expect}" ]]; then
    echo "Missing environment variable: $expect"
    echo "Expected: $expected"
    exit 1
  fi
done
if ! [[ -f "Dockerfile" ]]; then
  echo "Missing Dockerfile. exiting"
  exit 1
fi
PLATFORMS="${PLATFORMS:-linux/amd64,linux/arm64}"
# Fetch all tags and set most recent as a variable
git fetch --prune --unshallow
tag=$(git describe --tags)

echo "Login to container registry"
# Container registry credentials stored as environment variables (from github secrets when run in github-actions
echo "$REGISTRY_PASSWORD" | docker login ${REGISTRY_URL} -u="$REGISTRY_USERNAME" --password-stdin
# Build Dockerfile and use git tag as docker tag
echo "Build + push multi-arch docker container"
docker buildx build \
  --platform $PLATFORMS \
  -t $REGISTRY_APPNAME:$tag \
  -t $REGISTRY_APPNAME:latest \
  --push .
echo "Container(s) pushed to registry!"

# ---- ^ Docker Build ^ --- v Github Release v ---- #

echo "Creating git release..."
# Get commit message for selected tag
commit_message="$(git for-each-ref refs/tags/${tag} --format='%(contents)' | head -n1)"
# Create release
release_response=$(curl -sXPOST \
  -H "Content-Type: application/json" \
  -H "Authorization: token ${GIT_TOKEN}" \
  --data "{\"tag_name\": \"${tag}\", \"target_commitish\": \"${REPO_BRANCH}\", \"name\": \"${REPO_NAME}-${tag}\", \"body\": \"${commit_message}\", \"draft\": false, \"prerelease\": false}" \
  https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases)

# If the release was created successfully, the json response will contain an id
release_id=$(echo "$release_response" | jq -r '.id')
echo "Release ID: $release_id"
if [[ -n $release_id ]] && [[ "$release_id" != "null" ]]; then
  echo "Release complete: ${REGISTRY_URL}/${REGISTRY_APPNAME}:${tag}"
  exit 0
else
  echo "Could not get id from release response. Container pushed"
  exit 1
fi
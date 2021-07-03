#!/bin/bash

echo "Tag release, multi-arch-build and push"
echo "Check environment variables are set..."
expected="REGISTRY_USERNAME REGISTRY_PASSWORD REGISTRY_URL REGISTRY_APPNAME GIT_TOKEN"
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
# Get commit message for selected tag
commit_message="$(git for-each-ref refs/tags/$tag --format='%(contents)' | head -n1)"
# Container registry credentials stored as environment variables from github secrets
echo "Creating git release..."
# Build json with tag + commit message
curl_data='{"tag_name": "'$tag'", "target_commitish": "main", "name": "tools-'$tag'", "body": "'$commit_message'", "draft": false, "prerelease": false}'
# Sanity check (does json render through jq)
echo "Data: $curl_data"
echo "$curl_data" | jq '.'
# Build, print and execute curl to create a new release with the github api
curl_post="curl -sXPOST -H \"Content-Type: application/json\" -H \"Authorization: token $GIT_TOKEN\" --data '$curl_data' https://api.github.com/repos/mathew-fleisch/tools/releases"
echo "curl: "
echo "$curl_post"
release_response="$(eval $curl_post)"
echo "Release Response: $release_response"
echo "$release_response" | jq '.'
# If the release was created, the json response will contain an id
release_id=$(echo "$release_response" | jq -r '.id')
echo "Release ID: $release_id"
if [[ -n $release_id ]] && [[ "$release_id" != "null" ]]; then
  echo "Login to container registry"
  echo "$REGISTRY_PASSWORD" | docker login ${REGISTRY_URL} -u="$REGISTRY_USERNAME" --password-stdin
  # Build Dockerfile and use git tag as docker tag
  echo "Build + push multi-arch docker container"
  docker buildx build \
    --platform $PLATFORMS \
    -t $REGISTRY_APPNAME:$tag \
    -t $REGISTRY_APPNAME:latest \
    --push .
  echo "Release complete: ${REGISTRY_URL}/${REGISTRY_APPNAME}:${tag}"
  exit 0
else
  echo "Could not get release id from response. Skip upload and docker push."
  exit 1
fi
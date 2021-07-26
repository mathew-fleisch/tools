#!/bin/bash
##shellcheck disable=SC2164,SC2086

 SC2034
echo "Multi-arch-build and push"
# Check dependencies
expected="curl docker "
for expect in $expected; do
    if ! command -v $expect > /dev/null; then
    echo "Missing dependency: $expect"
    exit 1
    fi
done

echo "Check environment variables are set..."
expected="REGISTRY_USERNAME REGISTRY_PASSWORD REGISTRY_URL REGISTRY_APPNAME TARGET_DOCKERFILE"
for expect in $expected; do
  if [[ -z "${!expect}" ]]; then
    echo "Missing environment variable: $expect"
    echo "Expected: $expected"
    exit 1
  fi
done
if ! [[ -f "$TARGET_DOCKERFILE" ]]; then
  echo "Missing Dockerfile. exiting"
  exit 1
fi
PLATFORMS="${PLATFORMS:-linux/amd64,linux/arm64}"
pushd $(dirname $TARGET_DOCKERFILE)
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
  --push $(basename $TARGET_DOCKERFILE)
echo "Container(s) pushed to registry!"
popd


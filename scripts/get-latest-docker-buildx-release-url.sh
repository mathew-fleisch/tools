#!/bin/bash

# Format: 
# https://github.com/docker/buildx/releases/download/v0.6.0/buildx-v0.6.0.darwin-amd64
# https://github.com/docker/buildx/releases/download/v0.6.0/buildx-v0.6.0.darwin-arm64
# https://github.com/docker/buildx/releases/download/v0.6.0/buildx-v0.6.0.linux-amd64
# https://github.com/docker/buildx/releases/download/v0.6.0/buildx-v0.6.0.linux-arm-v6
# https://github.com/docker/buildx/releases/download/v0.6.0/buildx-v0.6.0.linux-arm-v7
# https://github.com/docker/buildx/releases/download/v0.6.0/buildx-v0.6.0.linux-arm64



os=$(uname | tr '[:upper:]' '[:lower:]')
arch=$(uname -m)
case $arch in
  armv6*) arch="arm-v6";;
  armv7*) arch="arm-v7";;
  aarch64) arch="arm64";;
  x86_64) arch="amd64";;
esac
# echo "os: $os"
# echo "arch: $arch"

allurls=$(curl -s https://api.github.com/repos/docker/buildx/releases/latest | jq -r .assets[].browser_download_url | grep $os-$arch)
echo $allurls
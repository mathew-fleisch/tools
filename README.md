# tools
This repo will hold common tools/scripts/containers that can be pulled into other projects

## Docker Container

The [Dockerfile](Dockerfile) in this repository installs some commonly used tools to be used as a base for other projects. Users are also set up for use with github-action runners and with "docker-in-docker" python3 is installed along with vim, git and other common command line tools.

#### Multi-arch docker builds

The [docker plugin buildx](https://api.github.com/repos/docker/buildx) uses these apt packages to facilitate building containers for multiple architectures:

```
binfmt-support qemu-user-static
```

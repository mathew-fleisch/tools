# tools
This repo will hold common tools/scripts/containers that can be pulled into other projects

## Docker Container
[![Release CI: multi-arch container build & push](https://github.com/mathew-fleisch/tools/actions/workflows/tag-release.yaml/badge.svg)](https://github.com/mathew-fleisch/tools/actions/workflows/tag-release.yaml)

The [Dockerfile](Dockerfile) in this repository installs some commonly used tools to be used as a base for other projects. Users are also set up for use with github-action runners and with "docker-in-docker" python3 is installed along with vim, git and other common command line tools.

#### Multi-arch docker builds

The [docker plugin buildx](https://api.github.com/repos/docker/buildx) uses these apt packages to facilitate building containers for multiple architectures:

```
binfmt-support qemu-user-static
```

## Projects

This container is used as a base for other projects that expect certain tools to be pre-installed. The [docker-dev-env](https://github.com/mathew-fleisch/docker-dev-env) project is intended to provide a development environment with devops related tools pre-installed. The [github-actions-runner](https://github.com/mathew-fleisch/github-actions-runner) project also has many tools pre-installed, but also includes the agent to run the container as a github-action self-hosted runner. 
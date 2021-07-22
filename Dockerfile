FROM debian:buster-slim
LABEL maintainer="Mathew Fleisch <mathew.fleisch@gmail.com>"

COPY scripts/getArch /usr/local/bin/getArch
ENV ASDF_DATA_DIR /opt/asdf
# Install apt dependencies
RUN rm /bin/sh && ln -s /bin/bash /bin/sh \
    && apt update \
    && DEBIAN_FRONTEND=noninteractive apt install -y curl wget apt-utils python3 python3-pip make build-essential openssl lsb-release libssl-dev apt-transport-https ca-certificates iputils-ping git vim jq zip sudo binfmt-support qemu-user-static ffmpeg rsync rbenv ruby-build \
    && curl -sSL https://get.docker.com/ | sh \
    && echo "%sudo ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && apt-get clean \
    && apt-get dist-upgrade -u -y \
    && useradd -ms /bin/bash github \
    && usermod -aG sudo github \
    && addgroup runners \
    && adduser github runners \
    && adduser github docker \
    && usermod -aG docker github \
    && python3 -m pip install --upgrade --force pip \
    && ln -s /usr/bin/python3 /usr/local/bin/python \
    && mkdir -p $ASDF_DATA_DIR \
    && chown -R github:runners $ASDF_DATA_DIR \
    && chmod -R g+w $ASDF_DATA_DIR \
    && git clone https://github.com/asdf-vm/asdf.git ${ASDF_DATA_DIR} --branch v0.8.1 \
    && echo "export ASDF_DATA_DIR=${ASDF_DATA_DIR}" | tee -a /root/.bashrc /home/github/.bashrc \
    && echo ". ${ASDF_DATA_DIR}/asdf.sh" | tee -a /root/.bashrc /home/github/.bashrc \
    && mkdir -p /root/.docker/cli-plugins \
    && mkdir -p /home/github/.docker/cli-plugins \
    && wget $(curl -s https://api.github.com/repos/docker/buildx/releases/latest | jq -r .assets[].browser_download_url | grep $(getArch) | grep -v darwin) -O /root/.docker/cli-plugins/docker-buildx \
    && cp /root/.docker/cli-plugins/docker-buildx /home/github/.docker/cli-plugins/docker-buildx \
    && chmod +x /root/.docker/cli-plugins/docker-buildx \
    && chmod +x /home/github/.docker/cli-plugins/docker-buildx \
    && docker buildx create --name mbuilder \
    && docker buildx use mbuilder \
    && docker buildx inspect --bootstrap \
    && wget https://raw.githubusercontent.com/fsaintjacques/semver-tool/master/src/semver -O /usr/local/bin/semver \
    && chmod +x /usr/local/bin/semver

CMD /bin/bash

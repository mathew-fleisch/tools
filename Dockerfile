FROM ubuntu:22.04
LABEL maintainer="Mathew Fleisch <mathew.fleisch@gmail.com>"
# The "kitchen sink" of a Dockerfile that includes many tools used in infrastructure/devops teams
COPY scripts/get-latest-docker-buildx-release-url.sh /root/get-latest-docker-buildx-release-url.sh
ENV ASDF_DATA_DIR /opt/asdf
# Install apt dependencies
COPY .tool-versions /root/.tool-versions
COPY pin /root/pin
RUN rm /bin/sh && ln -s /bin/bash /bin/sh \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y curl wget apt-utils python3 python3-pip make build-essential openssl lsb-release libssl-dev apt-transport-https ca-certificates iputils-ping git vim jq zip sudo binfmt-support qemu-user-static ffmpeg rsync rbenv ruby-build zlib1g-dev \
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
    && mkdir -p /root/.docker/cli-plugins \
    && mkdir -p /home/github/.docker/cli-plugins \
    && wget $(/root/get-latest-docker-buildx-release-url.sh) -O /root/.docker/cli-plugins/docker-buildx \
    && cp /root/.docker/cli-plugins/docker-buildx /home/github/.docker/cli-plugins/docker-buildx \
    && chmod +x /root/.docker/cli-plugins/docker-buildx \
    && chmod +x /home/github/.docker/cli-plugins/docker-buildx

# Install asdf
WORKDIR /root
RUN mkdir -p $ASDF_DATA_DIR \
    && chown -R github:runners $ASDF_DATA_DIR \
    && chmod -R g+w $ASDF_DATA_DIR \
    && git clone --depth 1 https://github.com/asdf-vm/asdf.git ${ASDF_DATA_DIR} --branch v0.8.1 \
    && echo "export ASDF_DATA_DIR=${ASDF_DATA_DIR}" | tee -a /root/.bashrc /home/github/.bashrc | tee -a /root/.bashrc \
    && echo ". ${ASDF_DATA_DIR}/asdf.sh" | tee -a /root/.bashrc /home/github/.bashrc | tee -a /root/.bashrc \
    && . $ASDF_DATA_DIR/asdf.sh \
    && cat .tool-versions | awk '{print $1}' | sort | uniq | xargs -I {} asdf plugin add {} \
    && asdf install

CMD /bin/bash -c '. ${ASDF_DATA_DIR}/asdf.sh && /bin/bash'

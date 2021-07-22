FROM alpine:latest
LABEL maintainer="Mathew Fleisch <mathew.fleisch@gmail.com>"
ENV ASDF_DATA_DIR /opt/asdf

# Install asdf dependencies
WORKDIR /root
COPY .tool-versions /root/.tool-versions
COPY pin /root/pin

RUN apk add --update bash curl git make go jq \
    && rm /bin/sh && ln -s /bin/bash /bin/sh \
    && ln -s /usr/bin/python3 /usr/local/bin/python 
RUN mkdir -p $ASDF_DATA_DIR \
    && git clone --depth 1 https://github.com/asdf-vm/asdf.git $ASDF_DATA_DIR \
    && . $ASDF_DATA_DIR/asdf.sh \
    && echo -e '\n. $ASDF_DATA_DIR/asdf.sh' >> $HOME/.bashrc \
    && echo -e '\n. $ASDF_DATA_DIR/asdf.sh' >> $HOME/.profile \
    && asdf update \
    && while IFS= read -r line; do asdf plugin add $(echo "$line" | awk '{print $1}'); done < .tool-versions \
    && asdf install

CMD /bin/sh -c "/bin/bash ${ASDF_DATA_DIR}/asdf.sh && /bin/bash"
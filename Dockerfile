FROM asciidoctor/docker-asciidoctor:latest

USER root

# Used by the polling script to calculate stable checksums.
RUN apk add --no-cache \
    bash \
    coreutils \
    findutils

COPY watch.sh /usr/local/bin/watch-asciidoc

RUN chmod +x /usr/local/bin/watch-asciidoc

WORKDIR /documents

ENTRYPOINT ["/usr/local/bin/watch-asciidoc"]

ARG ALPINE_TAG=3.21

FROM alpine:$ALPINE_TAG

ARG ALPINE_TAG

LABEL org.opencontainers.image.authors="Spritsail <alpine@spritsail.io>" \
      org.opencontainers.image.title="Alpine Linux" \
      org.opencontainers.image.url="https://github.com/gliderlabs/docker-alpine" \
      org.opencontainers.image.source="https://github.com/spritsail/alpine" \
      org.opencontainers.image.description="Alpine Linux base image" \
      org.opencontainers.image.version=${ALPINE_TAG}

# Override shell for sh-y debugging goodness
SHELL ["/bin/sh", "-exc"]

COPY skel/ /
ADD https://alpine.spritsail.io/spritsail-alpine.rsa.pub /etc/apk/keys

ENV ENV="/etc/profile"
RUN sed -i '1ihttps://alpine.spritsail.io/spritsail' /etc/apk/repositories \
 && apk --no-cache add \
        su-exec \
        tini

ENTRYPOINT ["/sbin/tini" , "--"]

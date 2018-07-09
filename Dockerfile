ARG SU_EXEC_VER=0.3
ARG ALPINE_TAG=3.8

FROM alpine:$ALPINE_TAG

ARG SU_EXEC_VER
ARG ALPINE_TAG

LABEL maintainer="Spritsail <alpine@spritsail.io>" \
      org.label-schema.vendor="Spritsail" \
      org.label-schema.name="Alpine Linux" \
      org.label-schema.url="https://github.com/gliderlabs/docker-alpine" \
      org.label-schema.description="Alpine Linux base image" \
      org.label-schema.version=${ALPINE_TAG} \
      io.spritsail.version.su-exec=${SU_EXEC_VER}

# Override shell for sh-y debugging goodness
SHELL ["/bin/sh", "-exc"]

COPY skel/ /
ENV ENV="/etc/profile"
RUN apk --no-cache add \
        tini \
        libressl \
 && wget -qO /sbin/su-exec https://github.com/frebib/su-exec/releases/download/v${SU_EXEC_VER}/su-exec-alpine-$(uname -m) \
 && chmod +x /sbin/su-exec \
 && apk --no-cache del openssl

ENTRYPOINT ["/sbin/tini" , "--"]

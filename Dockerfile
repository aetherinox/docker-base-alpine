# syntax=docker/dockerfile:1

# #
#   @project        Docker Image - Alpine Base
#   @usage          base image utilized for all docker images using alpine with s6-overlay integration
#   @arch           amd64
#   @file           Dockerfile
#   @repo           https://github.com/aetherinox/docker-base-alpine
# #

ARG ALPINE_VERSION="3.21.3"
FROM alpine:${ALPINE_VERSION} AS rootfs-stage

# #
#   alpine › args
# #

ARG REPO_AUTHOR="aetherinox"
ARG REPO_NAME="docker-base-alpine"
ARG S6_OVERLAY_VERSION="3.1.6.2"
ARG S6_OVERLAY_ARCH="x86_64"

# #
#   alpine › environment
# #

ENV ROOTFS=/root-out
ENV REL=v3.21
ENV ARCH=x86_64
ENV MIRROR=http://dl-cdn.alpinelinux.org/alpine
ENV PACKAGES=alpine-baselayout,\
alpine-keys,\
apk-tools,\
busybox,\
libc-utils

# #
#   alpine › install packages
# #

RUN \
  apk add --no-cache \
    bash \
    xz

# #
#   alpine › build rootfs
# #

RUN \
  mkdir -p "$ROOTFS/etc/apk" && \
  { \
    echo "$MIRROR/$REL/main"; \
    echo "$MIRROR/$REL/community"; \
  } > "$ROOTFS/etc/apk/repositories" && \
  apk --root "$ROOTFS" --no-cache --keys-dir /etc/apk/keys add --arch $ARCH --initdb ${PACKAGES//,/ } && \
  sed -i -e 's/^root::/root:!:/' /root-out/etc/shadow

# #
#   alpine › S6 > add overlay
# #

ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
RUN tar -C /root-out -Jxpf /tmp/s6-overlay-noarch.tar.xz
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${S6_OVERLAY_ARCH}.tar.xz /tmp
RUN tar -C /root-out -Jxpf /tmp/s6-overlay-${S6_OVERLAY_ARCH}.tar.xz

# #
#   alpine › S6 > add optional symlinks
# #

ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-noarch.tar.xz /tmp
RUN tar -C /root-out -Jxpf /tmp/s6-overlay-symlinks-noarch.tar.xz
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-arch.tar.xz /tmp
RUN tar -C /root-out -Jxpf /tmp/s6-overlay-symlinks-arch.tar.xz

# #
#   scratch
# #

FROM scratch
COPY --from=rootfs-stage /root-out/ /

# #
#   scratch › args
# #

ARG BUILDDATE
ARG VERSION
ARG REPO_AUTHOR="aetherinox"
ARG REPO_NAME="docker-base-alpine"
ARG MODS_VERSION="v3"
ARG PKG_INST_VERSION="v1"
ARG AETHERXOWN_VERSION="v1"
ARG WITHCONTENV_VERSION="v1"

# #
#   scratch › set labels
# #

LABEL org.opencontainers.image.authors="${REPO_AUTHOR}"
LABEL org.opencontainers.image.title="Alpine Base Image"
LABEL org.opencontainers.image.description="Alpine base image with s6-overlay integration"
LABEL org.opencontainers.image.source="https://github.com/${REPO_AUTHOR}/${REPO_NAME}"
LABEL org.opencontainers.image.repo.1="https://github.com/${REPO_AUTHOR}/${REPO_NAME}"
LABEL org.opencontainers.image.repo.2="https://github.com/thebinaryninja/${REPO_NAME}"
LABEL org.opencontainers.image.documentation="https://github.com/${REPO_AUTHOR}/${REPO_NAME}/wiki"
LABEL org.opencontainers.image.url="https://github.com/${REPO_AUTHOR}/${REPO_NAME}"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.architecture="amd64"
LABEL org.opencontainers.image.ref.name="main"
LABEL org.opencontainers.image.registry="local"
LABEL org.alpine.image.maintainers="${REPO_AUTHOR}"
LABEL org.alpine.image.build-version="Version:- ${VERSION} Date:- ${BUILDDATE}"

# #
#   scratch › add cdn > core
# #

ADD --chmod=755 "https://raw.githubusercontent.com/${REPO_AUTHOR}/${REPO_NAME}/docker/core/docker-images.${MODS_VERSION}" "/docker-images"
ADD --chmod=755 "https://raw.githubusercontent.com/${REPO_AUTHOR}/${REPO_NAME}/docker/core/package-install.${PKG_INST_VERSION}" "/etc/s6-overlay/s6-rc.d/init-mods-package-install/run"
ADD --chmod=755 "https://raw.githubusercontent.com/${REPO_AUTHOR}/${REPO_NAME}/docker/core/aetherxown.${AETHERXOWN_VERSION}" "/usr/bin/aetherxown"

# #
#   scratch › env vars
# #

ENV PS1="$(whoami)@$(hostname):$(pwd)\\$ " \
  HOME="/root" \
  TERM="xterm" \
  S6_CMD_WAIT_FOR_SERVICES_MAXTIME="0" \
  S6_VERBOSITY=1 \
  S6_STAGE2_HOOK=/docker-images \
  VIRTUAL_ENV=/aetherxpy \
  PATH="/aetherxpy/bin:$PATH"

RUN \
  echo "**** INSTALLING RUNTIME PACKAGES ****" && \
  apk add --no-cache \
    alpine-release \
    bash \
    nano \
    ca-certificates \
    catatonit \
    coreutils \
    curl \
    findutils \
    jq \
    netcat-openbsd \
    procps-ng \
    shadow \
    tzdata && \
  echo "**** CREATE USER 'dockerx' AND GENERATE STRUCTURE ****" && \
  groupmod -g 1000 users && \
  useradd -u 911 -U -d /config -s /bin/false dockerx && \
  usermod -G users dockerx && \
  mkdir -p \
    /app \
    /config \
    /defaults \
    /aetherxpy && \
  echo "**** CLEANUP ****" && \
  rm -rf \
    /tmp/*

# #
#   scratch › add local files
# #

COPY root/ /

# #
#   scratch › add entrypoint
# #

ENTRYPOINT ["/init"]

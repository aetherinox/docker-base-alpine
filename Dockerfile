# syntax=docker/dockerfile:1

# #
#   @project              Docker Image › Alpine Base › Dockerfile
#   @repo                 https://github.com/aetherinox/docker-base-alpine
#   @file                 Dockerfile
#   @usage                base image utilized for all docker images using Ubuntu with s6-overlay integration
#
#   @image:github         ghcr.io/aetherinox/alpine:latest
#                         ghcr.io/aetherinox/alpine:3.22
#                         ghcr.io/aetherinox/alpine:3.2
#                         ghcr.io/aetherinox/alpine:3
#
#   @image:dockerhub      aetherinox/alpine:latest
#                         aetherinox/alpine:3.22
#                         aetherinox/alpine:3.2
#                         aetherinox/alpine:3
#
#   @build                AMD64
#                         Build the image with:
#                             docker buildx build \
#                               --build-arg IMAGE_NAME=alpine \
#                               --build-arg IMAGE_ARCH=amd64 \
#                               --build-arg IMAGE_BUILDDATE=20260812 \
#                               --build-arg IMAGE_VERSION=3.22 \
#                               --build-arg IMAGE_RELEASE=stable \
#                               --build-arg IMAGE_REGISTRY=github \
#                               --tag aetherinox/alpine:latest \
#                               --tag aetherinox/alpine:3 \
#                               --tag aetherinox/alpine:3.2 \
#                               --tag aetherinox/alpine:3.22
#                               --attest type=provenance,disabled=true \
#                               --attest type=sbom,disabled=true \
#                               --output type=docker \
#                               --builder default \
#                               --file Dockerfile \
#                               --platform linux/amd64 \
#                               --allow network.host \
#                               --network host \
#                               --no-cache \
#                               --progress=plain \
#                               .
#
#                         ARM64
#                         For arm64, make sure you install QEMU first in docker; use the command:
#                             docker run --privileged --rm tonistiigi/binfmt --install all
#
#                         Build the image with:
#                             docker buildx build \
#                               --build-arg IMAGE_NAME=alpine \
#                               --build-arg IMAGE_ARCH=arm64 \
#                               --build-arg IMAGE_BUILDDATE=20260812 \
#                               --build-arg IMAGE_VERSION=3.22 \
#                               --build-arg IMAGE_RELEASE=stable \
#                               --build-arg IMAGE_REGISTRY=github \
#                               --tag aetherinox/alpine:latest \
#                               --tag aetherinox/alpine:3 \
#                               --tag aetherinox/alpine:3.2 \
#                               --tag aetherinox/alpine:3.22 \
#                               --attest type=provenance,disabled=true \
#                               --attest type=sbom,disabled=true \
#                               --output type=docker \
#                               --builder default \
#                               --file Dockerfile \
#                               --platform linux/arm64 \
#                               --allow network.host \
#                               --network host \
#                               --no-cache \
#                               --progress=plain \
#                               .
# #

ARG ALPINE_VERSION=3.22
FROM alpine:${ALPINE_VERSION} AS rootfs-stage

# #
#   arguments
#
#   ARGs are the only thing you should provide in your buildx command
#   or Github workflow. ENVs are set by args, or hard-coded values
#
#   IMAGE_ARCH          amd64
#                       arm64
#
#   The args below will get their value depending on what you set for IMAGE_ARCH:
#
#   UBUNTU_ARCH         amd64
#                       arm64
#
#   S6_OVERLAY_ARCH     x86_64
#                       aarch64
# #

ARG IMAGE_REPO_AUTHOR="aetherinox"
ARG IMAGE_REPO_NAME="docker-base-alpine"
ARG IMAGE_NAME="alpine"
ARG IMAGE_ARCH="amd64"
ARG IMAGE_SHA1="0000000000000000000000000000000000000000"
ARG IMAGE_REGISTRY="local"
ARG IMAGE_RELEASE="stable"
ARG IMAGE_BUILDDATE="20250101"
ARG IMAGE_VERSION="3.22"

ENV ALPINE_VERSION=${IMAGE_VERSION}
ENV ALPINE_ARCH="x86_64"
ENV S6_OVERLAY_VERSION="3.2.1.0"
ENV S6_OVERLAY_ARCH="x86_64"
ENV BASHIO_VERSION="0.16.2"

# #
#   alpine › environment
# #

ENV ROOTFS=/root-out
ENV MIRROR=http://dl-cdn.alpinelinux.org/alpine
ENV PACKAGES=alpine-baselayout,\
alpine-keys,\
apk-tools,\
busybox,\
libc-utils

# #
#   install packages
# #

RUN \
    apk add --no-cache \
        bash \
        xz

# #
#   alpine › build rootfs
# #

RUN \
    if [ "${IMAGE_ARCH}" = "armv7" ]; then \
        ALPINE_ARCH="arm"; \
    elif [ "${IMAGE_ARCH}" = "i386" ]; then \
        ALPINE_ARCH="i686"; \
    elif [ "${IMAGE_ARCH}" = "amd64" ]; then \
        ALPINE_ARCH="x86_64"; \
    elif [ "${IMAGE_ARCH}" = "arm64" ]; then \
        ALPINE_ARCH="aarch64"; \
    else \
        ALPINE_ARCH="${ALPINE_ARCH}"; \
    fi \
    \
    && mkdir -p "$ROOTFS/etc/apk" && \
    { \
        echo "$MIRROR/v$ALPINE_VERSION/main"; \
        echo "$MIRROR/v$ALPINE_VERSION/community"; \
    } > "$ROOTFS/etc/apk/repositories" && \
    apk --root "$ROOTFS" --no-cache --keys-dir /etc/apk/keys add --arch $ALPINE_ARCH --initdb ${PACKAGES//,/ } && \
    sed -i -e 's/^root::/root:!:/' $ROOTFS/etc/shadow

# #
#   Alpine › S6 > add overlay & optional symlinks
#
#   TAR         --xz, -J                      Use xz for compressing or decompressing the archives. See section Creating and Reading
#                                                 Compressed Archives.
#               --get, -x                     Same as ‘--extract’
#                                             Extracts members from the archive into the file system. See section How to Extract Members
#                                                 from an Archive.
#               --verbose, -v                 Specifies that tar should be more verbose about the operations it is performing. This
#                                                 option can be specified multiple times for some operations to increase the amount
#                                                 of information displayed. See section Checking tar progress.
#               --file=archive, -f archive    Tar will use the file archive as the tar archive it performs operations on, rather
#                                                 than tar’s compilation dependent default. See section The ‘--file’ Option.
#               --directory=dir, -C           Dir When this option is specified, tar will change its current directory to dir
#                                                 before performing any operations. When this option is used during archive creation,
#                                                 it is order sensitive. See section Changing the Working Directory.
# #

RUN \
    if [ "${IMAGE_ARCH}" = "armv7" ]; then \
        S6_OVERLAY_ARCH="arm"; \
    elif [ "${IMAGE_ARCH}" = "i386" ]; then \
        S6_OVERLAY_ARCH="i686"; \
    elif [ "${IMAGE_ARCH}" = "amd64" ]; then \
        S6_OVERLAY_ARCH="x86_64"; \
    elif [ "${IMAGE_ARCH}" = "arm64" ]; then \
        S6_OVERLAY_ARCH="aarch64"; \
    else \
        S6_OVERLAY_ARCH="${UBUNTU_ARCH}"; \
    fi \
    \
    && wget -P /tmp "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz" && \
       tar -C $ROOTFS -Jxpf /tmp/s6-overlay-noarch.tar.xz && \
    wget -P /tmp "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${S6_OVERLAY_ARCH}.tar.xz" && \
       tar -C $ROOTFS -Jxpf /tmp/s6-overlay-${S6_OVERLAY_ARCH}.tar.xz && \
    wget -P /tmp "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-arch.tar.xz" && \
       tar -C $ROOTFS -Jxpf /tmp/s6-overlay-symlinks-arch.tar.xz && \
    wget -P /tmp "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-noarch.tar.xz" && \
       tar -C $ROOTFS -Jxpf /tmp/s6-overlay-symlinks-noarch.tar.xz && unlink $ROOTFS/usr/bin/with-contenv

# #
#   scratch
# #

FROM scratch
COPY --from=rootfs-stage $ROOTFS/ /

# #
#   scratch › args
# #

ARG IMAGE_REPO_AUTHOR="aetherinox"
ARG IMAGE_REPO_NAME="docker-base-alpine"
ARG IMAGE_NAME="alpine"
ARG IMAGE_ARCH="amd64"
ARG IMAGE_SHA1="0000000000000000000000000000000000000000"
ARG IMAGE_REGISTRY="local"
ARG IMAGE_RELEASE="stable"
ARG IMAGE_BUILDDATE="20250101"
ARG IMAGE_VERSION="3.22"

ENV ALPINE_VERSION=${IMAGE_VERSION}
ENV ALPINE_ARCH="x86_64"

ENV S6_OVERLAY_VERSION="3.2.1.0"
ENV S6_OVERLAY_ARCH="x86_64"
ENV BASHIO_VERSION="0.16.2"

ENV MODS_VERSION="v3"
ENV PKG_INST_VERSION="v1"
ENV AETHERXOWN_VERSION="v1"
ENV WITHCONTENV_VERSION="v1"

# #
#   scratch › set labels
# #

LABEL org.opencontainers.image.authors="${IMAGE_REPO_AUTHOR}"
LABEL org.opencontainers.image.vendor="${IMAGE_REPO_AUTHOR}"
LABEL org.opencontainers.image.title="${IMAGE_NAME:-Alpine} (Base) ${ALPINE_VERSION}"
LABEL org.opencontainers.image.description="${IMAGE_NAME:-Alpine} base image with s6-overlay integration"
LABEL org.opencontainers.image.created=
LABEL org.opencontainers.image.source="https://github.com/${IMAGE_REPO_AUTHOR}/${IMAGE_REPO_NAME}"
LABEL org.opencontainers.image.documentation="https://github.com/${IMAGE_REPO_AUTHOR}/${IMAGE_REPO_NAME}/wiki"
LABEL org.opencontainers.image.issues="https://github.com/${IMAGE_REPO_AUTHOR}/${IMAGE_REPO_NAME}/issues"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.version="${ALPINE_VERSION}"
LABEL org.opencontainers.image.branch="main"
LABEL org.opencontainers.image.registry="${IMAGE_REGISTRY:-local}"
LABEL org.opencontainers.image.release="${IMAGE_RELEASE:-stable}"
LABEL org.opencontainers.image.development="false"
LABEL org.opencontainers.image.sha="${IMAGE_SHA1:-0000000000000000000000000000000000000000}"
LABEL org.opencontainers.image.architecture="${IMAGE_ARCH:-amd64}"
LABEL org.ubuntu.image.maintainers="${IMAGE_REPO_AUTHOR}"
LABEL org.ubuntu.image.version="Version: ${ALPINE_VERSION} Date: ${IMAGE_BUILDDATE:-20250615}"
LABEL org.ubuntu.image.release="${IMAGE_RELEASE:-stable}"
LABEL org.ubuntu.image.sha="${IMAGE_SHA1:-0000000000000000000000000000000000000000}"
LABEL org.ubuntu.image.architecture="${IMAGE_ARCH:-amd64}"
LABEL org.s6overlay.image.version="${S6_OVERLAY_VERSION:-3.0.0.0}"
LABEL org.s6overlay.image.architecture="${S6_OVERLAY_ARCH:-x86_64}"

# #
#   scratch › add cdn > core
# #

ADD --chmod=755 "https://raw.githubusercontent.com/${IMAGE_REPO_AUTHOR}/${IMAGE_REPO_NAME}/docker/core/docker-images.${MODS_VERSION}" "/docker-images"
ADD --chmod=755 "https://raw.githubusercontent.com/${IMAGE_REPO_AUTHOR}/${IMAGE_REPO_NAME}/docker/core/package-install.${PKG_INST_VERSION}" "/etc/s6-overlay/s6-rc.d/init-mods-package-install/run"
ADD --chmod=755 "https://raw.githubusercontent.com/${IMAGE_REPO_AUTHOR}/${IMAGE_REPO_NAME}/docker/core/aetherxown.${AETHERXOWN_VERSION}" "/usr/bin/aetherxown"
ADD --chmod=755 "https://raw.githubusercontent.com/${IMAGE_REPO_AUTHOR}/${IMAGE_REPO_NAME}/docker/core/with-contenv.${WITHCONTENV_VERSION}" "/usr/bin/with-contenv"

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

# #
#   env variables
# #

ENV USER0="root"
ENV USER1="dockerx"
ENV UUID0=0
ENV UUID1=999
ENV GUID0=0
ENV GUID1=999

# #
#   install packages
# #

RUN \
    echo "**** INSTALLING RUNTIME PACKAGES ****" && \
    apk add --no-cache \
        alpine-release \
        bash \
        sudo \
        nano \
        ca-certificates \
        catatonit \
        coreutils \
        curl \
        findutils \
        jq \
        git \
        netcat-openbsd \
        procps-ng \
        shadow \
        tzdata && \
    echo "**** Creating user 'dockerx' and structure ****" && \
    sudo sed -i "s|^UID_MIN.*|UID_MIN\t\t\t  100|" /etc/login.defs && \
    useradd --uid ${UUID1} \
      --user-group \
      --home /config \
      --shell /bin/false \
      ${USER1} && \
    usermod -aG ${USER1} ${USER1} && \
        usermod -aG users ${USER1} && \
    mkdir -p \
        /app \
        /config \
        /defaults \
        /aetherxpy && \
    mkdir -p /etc/sudoers.d/ && \
    echo ${USER1} ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/${USER1} && \
    chmod 0440 /etc/sudoers.d/${USER1} && \
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

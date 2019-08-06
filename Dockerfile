FROM debian:stretch-slim

ENV WORKDIR=/workdir \
    BUILDS=/workdir/builds \
    HOSTNAME=RaspiDeb64 \
    BUILD_ARCH=arm64 \
    QEMU_ARCH=aarch64 \
    VARIANT=debian \
    OS_RELEASE=stretch \
    OS_VERSION=dirty


RUN apt-get update && apt-get install -y \
    iproute2 \
    binfmt-support \
    gpg \
    qemu \
    qemu-user \
    qemu-user-static \
    debootstrap \
    ruby-rspec \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/* && \
    gem install serverspec

WORKDIR ${WORKDIR}

COPY scripts/* ${WORKDIR}/
COPY files/ ${WORKDIR}/files/
COPY test/ ${WORKDIR}/test/

ENTRYPOINT ["./build.sh"]

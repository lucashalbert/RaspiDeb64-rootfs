FROM debian:stretch-slim

ENV WORKDIR=/workdir \
    BUILDS=/workdir/builds


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

COPY scripts/* common_vars ${WORKDIR}/
COPY files/ ${WORKDIR}/files/
COPY test/ ${WORKDIR}/test/

ENTRYPOINT ["./build.sh"]

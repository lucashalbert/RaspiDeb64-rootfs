#!/bin/bash
set -ex

# this script must be run in a container
if [ ! -f /.dockerenv ]; then
  echo "ERROR: script must be run in a container"
  exit 1
fi

# this script has to be run in a privileged container
ip link add dummy0 type dummy >/dev/null
if [[ $? -gt 0 ]]; then
    echo "ERROR: script must be run in a privileged container"
    exit 1
fi
ip link delete dummy0 >/dev/null

# check if binfmt_misc is enabled
mount binfmt_misc -t binfmt_misc /proc/sys/fs/binfmt_misc
BINFMT_MISC="/proc/sys/fs/binfmt_misc/status"
if [[ ! -f ${BINFMT_MISC} || $(cat ${BINFMT_MISC}) != "enabled" ]]; then
    echo "ERROR: binfmt_misc is not enabled. Verify that the host OS has binfmt-support installed"
    exit 1
fi

# build Debian rootfs for ARCH={armhf,arm64,mips,i386,amd64}
# - Debian armhf = ARMv6/ARMv7
# - Debian arm64 = ARMv8/Aarch64
# - Debian mips  = MIPS
# - Debian i386  = Intel/AMD 32-bit
# - Debian amd64 = Intel/AMD 64-bit
HOSTNAME="${HOSTNAME:-RaspiDeb64}"
BUILD_ARCH="${BUILD_ARCH:-arm64}"
QEMU_ARCH="${QEMU_ARCH:-aarch64}"
VARIANT="${VARIANT:-debian}"
OS_VERSION="${OS_VERSION:-dirty}"
OS_RELEASE="${OS_RELEASE:-stretch}"
ROOTFS_DIR="/debian-${BUILD_ARCH}"
DEBOOTSTRAP_URL="http://ftp.debian.org/debian"
DEFAULT_PACKAGES_INCLUDE="apt-transport-https,avahi-daemon,bash-completion,binutils,ca-certificates,curl,git-core,htop,locales,net-tools,ntp,openssh-server,parted,sudo,usbutils,wget,libpam-systemd"
DEFAULT_PACKAGES_EXCLUDE="debfoster"
BINFMT_STATUS="/proc/sys/fs/binfmt_misc/status"



# cleanup
mkdir -p /workspace
rm -rf "${ROOTFS_DIR}"

# define ARCH dependent settings
if [ -z "${QEMU_ARCH}" ]; then
  DEBOOTSTRAP_CMD="debootstrap"
else
  DEBOOTSTRAP_CMD="qemu-debootstrap"

  # tell Linux how to start binaries that need emulation to use Qemu
  update-binfmts --enable "qemu-${QEMU_ARCH}"

  # check if binfmt_misc is enabled
  if [[ ! -f ${BINFMT_STATUS} || $(cat ${BINFMT_STATUS}) != "enabled" ]]; then
    echo "ERROR: binfmt_misc is not enabled. Verify that the host OS has binfmt-support installed"
    exit 1
  fi
fi

# debootstrap a minimal Debian stretch rootfs
${DEBOOTSTRAP_CMD} \
  --arch="${BUILD_ARCH}" \
  --include="${DEFAULT_PACKAGES_INCLUDE}" \
  --exclude="${DEFAULT_PACKAGES_EXCLUDE}" \
  ${OS_RELEASE} \
  "${ROOTFS_DIR}" \
  "${DEBOOTSTRAP_URL}"

# modify/add image files directly
cp -R ${WORKDIR}/files/* "$ROOTFS_DIR/"

# set up mount points for the pseudo filesystems
mkdir -p $ROOTFS_DIR/{proc,sys,dev/pts}

mount -o bind /dev "$ROOTFS_DIR/dev"
mount -o bind /dev/pts "$ROOTFS_DIR/dev/pts"
mount -t proc none "$ROOTFS_DIR/proc"
mount -t sysfs none "$ROOTFS_DIR/sys"

# make our build directory the current root
# and install the Rasberry Pi firmware, kernel packages,
# docker tools and some customizations
chroot "$ROOTFS_DIR" \
       /usr/bin/env \
       HOSTNAME="$HOSTNAME" \
       OS_VERSION="$OS_VERSION" \
       BUILD_ARCH="$BUILD_ARCH" \
       VARIANT="$VARIANT" \
       /bin/bash < ${WORKDIR}/chroot-script.sh

# unmount pseudo filesystems
umount -l "$ROOTFS_DIR/dev/pts"
umount -l "$ROOTFS_DIR/dev"
umount -l "$ROOTFS_DIR/proc"
umount -l "$ROOTFS_DIR/sys"

# ensure that there are no leftover artifacts in the pseudo filesystems
rm -rf "$ROOTFS_DIR/{dev,sys,proc}/*"

# package rootfs tarball
umask 0000

pushd /workspace
ARCHIVE_NAME="rootfs-${BUILD_ARCH}-${VARIANT}-${OS_RELEASE}-${OS_VERSION}-$(date "+%Y%m%dT%H%M%S").tar.gz"
tar -czf "${BUILDS}/${ARCHIVE_NAME}" -C "${ROOTFS_DIR}/" .
sha256sum "${BUILDS}/${ARCHIVE_NAME}" > "${BUILDS}/${ARCHIVE_NAME}.sha256"
popd

# test if rootfs is OK
ROOTFS_TAR=${ARCHIVE_NAME} HOSTNAME="${HOSTNAME}" VARIANT="${VARIANT}" ${WORKDIR}/test.sh

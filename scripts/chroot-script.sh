#!/bin/bash
set -ex

# upgrade to latest Debian package versions
apt-get update
apt-get upgrade -y


### configure network ###

# set ethernet interface eth0 to dhcp
cat > /etc/network/interfaces.d/eth0 << EOF
allow-hotplug eth0
iface eth0 inet dhcp
EOF

# configure and enable resolved
ln -sfv /run/systemd/resolve/resolv.conf /etc/resolv.conf
DEST=$(readlink -m /etc/resolv.conf)
mkdir -p "$(dirname "$DEST")"
touch /etc/resolv.conf
systemctl enable systemd-resolved

# enable ntp with timesyncd
sed -i 's|#Servers=|Servers=|g' /etc/systemd/timesyncd.conf
systemctl enable systemd-timesyncd

# set default locales to 'en_US.UTF-8'
echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen
locale-gen

echo 'locales locales/default_environment_locale select en_US.UTF-8' | debconf-set-selections
dpkg-reconfigure -f noninteractive locales


### RaspiDeb64 default settings ###

# set hostname
echo "$HOSTNAME" > /etc/hostname

# install skeleton files from /etc/skel for root user
cp /etc/skel/{.bash_prompt,.bashrc,.profile} /root/

# cleanup APT cache and lists
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# set RaspiDeb64 version infos
echo "OS=\"RaspiDeb64/${BUILD_ARCH}\"" >> /etc/os-release
echo "OS_VERSION=\"${OS_VERSION}\"" >> /etc/os-release

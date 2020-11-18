#!/bin/bash

# Copyright (C) 2020 Boulder Engineering Studio
# Author: Erin Hensel <hens0093@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

export CUSTOM_IMG_NAME=custom.img

RSYNC_FLAGS="-vh --progress --modify-window=1 --recursive --ignore-errors"
LODEV=/dev/loop990

if [ -z "$1" ] ; then
    echo "No hostname given"
    exit 1
fi

do_umount() {
    RETURNCODE=$?
    if grep -qs '/mnt' /proc/mounts; then
        sudo umount /mnt
    fi
    losetup ${LODEV} > /dev/null 2>&1 && sudo losetup -d ${LODEV}
    return $RETURNCODE
}

do_umount
set -e
set -x

sudo echo "Creating custom image"
dd if=/dev/zero of=./${CUSTOM_IMG_NAME} bs=4M count=512

sfdisk ${CUSTOM_IMG_NAME} <<EOF
label: dos
label-id: 0x738a4d67
device: new.img
unit: sectors

${CUSTOM_IMG_NAME}1 : start=8192, size=524288, type=c, bootable
${CUSTOM_IMG_NAME}2 : start=532480, size=3661824, type=83, bootable
EOF

CONTAINER=$(docker run -d --rm raspi-custom sleep 60)
docker export ${CONTAINER} > custom-root.tar

sudo losetup -P ${LODEV} ${CUSTOM_IMG_NAME}
trap 'do_umount' ERR

sudo mkfs.fat ${LODEV}p1
sudo mount ${LODEV}p1 /mnt
sudo tar xf boot.tar -C /mnt
sudo rsync ${RSYNC_FLAGS} boot-overlay/ /mnt
sudo umount /mnt

sudo mkfs.ext4 ${LODEV}p2
sudo mount ${LODEV}p2 /mnt
sudo tar xf custom-root.tar -C /mnt

sudo /bin/bash -c "echo $1 > /mnt/etc/hostname"

PIDOCK_README=$(cat <<EOF
This raspberry pi has been customized with the Dockerfile
in this directory using the pidock utility

See https://github.com/eringr/pidock for more information
EOF
)

sudo mkdir -p /mnt/pidock
sudo /bin/bash -c "echo '$PIDOCK_README' > /mnt/pidock/README.txt"
sudo cp Dockerfile /mnt/pidock

do_umount

echo "Success"

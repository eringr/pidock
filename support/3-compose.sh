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

. $(dirname "$0")/functions.sh

if [ -z "$1" ] ; then
    echo "No hostname given"
    exit 1
fi

if [ ! -f "${PT_FILENAME}" ] ; then
    echo "No partition table found (${PT_FILENAME}). Run 'extract' first!"
    exit 1
fi

if [ -z "$CUSTOM_IMG_SIZE" ] ; then
    export CUSTOM_IMG_SIZE=4096
fi

do_umount
set -e
set -x

# Removing previous loopback device
losetup -a | grep "${CUSTOM_IMG_NAME}" | awk -F: '{ print $1 }' | \
    xargs -r sudo losetup -d

echo "Creating custom image"

# Initialize image file
dd if=/dev/zero of=./${CUSTOM_IMG_NAME} bs=1M count=${CUSTOM_IMG_SIZE}
# Copying partition table from base Raspbian image (saved in 'extract')
sfdisk ${CUSTOM_IMG_NAME} < "${PT_FILENAME}"
# Increase the linux partition size to the remaining space within CUSTOM_IMG_SIZE
echo ", +" | sfdisk custom.img -N 2

# Create loopback device
sudo losetup -fP ${CUSTOM_IMG_NAME}
LODEV=$(losetup -a | grep "${CUSTOM_IMG_NAME}" | awk -F: '{ print $1 }')
trap 'do_umount' ERR

CONTAINER=$(docker run -d --rm raspi-custom sleep 60)
docker export ${CONTAINER} > custom-root.tar

sudo mkfs.fat ${LODEV}p1
sudo mount ${LODEV}p1 /mnt
sudo tar xf boot.tar -C /mnt --numeric-owner
sudo rsync ${RSYNC_FLAGS} boot-overlay/ /mnt
sudo umount /mnt

sudo mkfs.ext4 ${LODEV}p2
sudo mount ${LODEV}p2 /mnt
sudo tar xf custom-root.tar -C /mnt --numeric-owner

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

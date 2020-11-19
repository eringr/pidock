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

if [ -z "$1" ] ; then
    echo "No file given"
    exit 1
fi

. $(dirname "$0")/functions.sh

do_umount
set -e

sfdisk -d "${1}" > "${PT_FILENAME}"

losetup -a | grep "${1}" | awk -F: '{ print $1 }' | \
    xargs -r sudo losetup -d
sudo losetup -fP ${1}
LODEV=$(losetup -a | grep "${1}" | awk -F: '{ print $1 }')
trap 'do_umount' ERR

echo "Creating boot.tar"

sudo mount ${LODEV}p1 /mnt
sudo tar cf boot.tar -C /mnt --numeric-owner .
sudo chown $(whoami) boot.tar
sudo umount /mnt

echo "Creating root.tar"

sudo mount ${LODEV}p2 /mnt
sudo tar cf root.tar -C /mnt --numeric-owner .
sudo chown $(whoami) root.tar

do_umount

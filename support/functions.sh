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

function do_umount() {
    RETURNCODE=$?
    if grep -qs '/mnt' /proc/mounts; then
        sudo umount /mnt
    fi
    if [ -n "${LODEV}" ]; then
        sudo losetup -d "${LODEV}"
    fi
    return $RETURNCODE
}

export PT_FILENAME="partition_table.txt"

#!/usr/bin/env python3

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

import sys
import argparse
import subprocess

_default_dev='/dev/mmcblk0'
_default_host='raspberrypi'
_default_passwd='raspberry'
_default_img='raspbian.img'

scripts = {
    'extract': 'support/1-extract.sh',
    'build': 'support/2-build.sh',
    'compose': 'support/3-compose.sh',
    'flash': 'support/4-flash.sh',
}

def run_script(script, args=[]):
    command = ['/bin/bash', scripts[script]] + args

    proc = subprocess.Popen(command)
    proc.wait()
    if proc.returncode == 0:
        return True
    else:
        print('Encountered error {} running {}'.format(
            proc.returncode,
            script
        ))
        return False

def main(args):
    dev_prompt_actions = ['all', 'flash']
    if args.action in dev_prompt_actions and not args.dev:
        print(
            'WARNING: This will overwrite the contents of {}'.format(
                _default_dev
            )
        )
        response = input('Proceed? [y/N]: ')
        if response.lower() != 'y':
            print('aborting')
            return

    device = args.dev if args.dev else _default_dev
    host = args.host if args.host else _default_host
    passwd = args.passwd if args.passwd else _default_passwd
    img = args.img if args.img else _default_img

    all_actions = [
        ('extract', lambda: run_script('extract', [img])),
        ('build', lambda: run_script('build', [passwd])),
        ('compose', lambda: run_script('compose', [host])),
        ('flash', lambda: run_script('flash', [device])),
    ]

    actions = None
    if args.action == 'all':
        actions = all_actions
    else:
        actions = [a for a in all_actions if a[0] == args.action]

    for action in actions:
        print('Doing {}'.format(action[0]))
        if not action[1]():
            print('Failed {}'.format(action[0]))
            break

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument(
        'action',
        choices=['all', 'extract', 'build', 'compose', 'flash']
    )
    parser.add_argument('--host', type=str)
    parser.add_argument('--dev', type=str)
    parser.add_argument('--passwd', type=str)
    parser.add_argument('--img', type=str)
    args = parser.parse_args()
    main(args)

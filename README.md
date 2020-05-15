
# Raspberry pi custom image creator "pidock"

TIRED: Maintaining your fleet of raspberry pi devices by running commands and
writing things on them ad-hoc and probably replicating by manually creating
large, corruptible disk images with undocumented contents

WIRED: Maintaining your fleet of raspberry pi devices by generating disk images
from a small repository containing their IP in one place concentrated enough
to be self-documenting and highly reproducible, able to be deployed onto the
latest version of an upstream base image

## Requirements

To run commands as pi root during image build, the host machine must be
set up with binfmt_misc to run qemu for arm binaries

On ubuntu 19: `apt install qemu-user-static qemu-user-binfmt`

Another easy (but insecure) method to do this is to run the following command

`docker run --rm --privileged multiarch/qemu-user-static --reset -p yes`

See https://github.com/multiarch/qemu-user-static

Also requires python3 and docker

## How to use

Move desired raspbian base disk image to file `raspbian.img`

```
./pidock.py <action>
    [--host <hostname=raspberrypi>]
    [--passwd <password=raspberry>]
    [--dev <flash_device=/dev/mmcblk0>]
    [--img <base_image=raspbian.img>]
```
Where action is one of the following

`all` - Does the same as the next four commands in order\
`extract` - Extracts files from raspbian.img to run in docker\
`build` - Builds docker image from extracted files and custom additions\
`compose` - Creates custom.img from built docker image\
`flash` - Flashes custom.img onto memory device (default: /dev/mmcblk0)

Use Dockerfile to build the pi's root as if it were a docker image.  Example
simply changes pi's password to that specified by --passwd instead of the
normal 'raspberry'.  And installs vim, because why not?

Files in boot-overlay and root-overlay will be copied onto their respective
partition.  For example, touching 'ssh' on the boot partition
will cause raspbian to enable ssh.

An example wpa_supplicant.conf is provided; if copied into boot-overlay,
raspbian will use its ssid/psk information and auto connect on first boot.

## Permissions

Note: currently requires sudo access to work around multiple permission issues

## Author

Erin Hensel `<hens0093@gmail.com>`; all copyrights assigned to:

Boulder Engineering Studio `<info@boulderes.com>`\
3297 Walnut St\
Boulder, CO 80301

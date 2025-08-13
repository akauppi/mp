#!/bin/bash
set -e

# espflash
#
# 'espflash' is needed for 'esp-hal' flashing, but not necessarily for normal development. CHECK THIS OUT AND
# RE-ENABLE IF NEEDED. Installing by 'cargo install' takes quite some time, so not bringing this in, unless
# needed for all users.
#
# tbd. TAKES A LONG TIME: see if there's a faster ready-binary way?
#
sudo DEBIAN_FRONTEND=noninteractive apt install -y pkg-config libudev-dev
cargo install espflash

# Write access needed for 'espflash' to flourish. ('/dev/ttyUSB0')
# NOTE!  MP MUST BE RESTARTED for this change to take effect!!
sudo usermod -a -G dialout ${USER}

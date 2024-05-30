#!/bin/bash
set -e

# Based on:
#   - Probe.rs > Installation
#     -> https://probe.rs/docs/getting-started/installation/
#   - xx
#     -> https://probe.rs/docs/getting-started/probe-setup/#linux%3A-udev-rules

# DISABLED: these are only needed for "building probe-rs from source". Thus.. skipping for now.
#sudo DEBIAN_FRONTEND=noninteractive \
#  apt install -y pkg-config libudev-dev

# Note: Alternatively, we could install by:
#   <<
#    $ cargo binstall probe-rs-tools
#   <<
#
INSTALL_URL=https://github.com/probe-rs/probe-rs/releases/latest/download/probe-rs-tools-installer.sh
curl --proto '=https' --tlsv1.2 -LsSf ${INSTALL_URL} | sh

# Shell completion
#
# NOTE:
#   '~/.zfunc/' must exist; otherwise the command fails ('probe-rs' docs don't mention..)
#
install -d ~/.zfunc
probe-rs complete install

# Prepare udev rules
_RULES_FILE=/etc/udev/rules.d/69-probe-rs.rules

curl --proto '=https' --tlsv1.2 -LsSf https://probe.rs/files/69-probe-rs.rules -o a.file
sudo mv a.file ${_RULES_FILE}
  sudo chown ${_RULES_FILE} root
  sudo chgrp ${_RULES_FILE} root

sudo udevadm control --reload

sudo udevadm trigger

# "If you're still unable to access the debug probes after following these steps, try adding your user to the plugdev group.”
#
sudo usermod -a -G plugdev ${USER}

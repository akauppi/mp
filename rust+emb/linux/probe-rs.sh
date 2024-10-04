#!/bin/bash
set -e

# Based on:
#   - Probe.rs > Installation
#     -> https://probe.rs/docs/getting-started/installation/

#|INSTALL_URL=https://github.com/probe-rs/probe-rs/releases/latest/download/probe-rs-tools-installer.sh
#|  # 0.24 specific: https://github.com/probe-rs/probe-rs/releases/download/v0.24.0/probe-rs-tools-installer.sh
#|
#|curl --proto '=https' --tlsv1.2 -LsSf ${INSTALL_URL} | sh

# Install FROM GITHUB (takes time!)
#
# Reasons:
#     There's an issue where ESP32-C3 seems to work against its spec, and this is a "wont-fix" for probe-rs
#     See [here](https://github.com/probe-rs/probe-rs/issues/2818#issuecomment-2358791448). You *can* - if you want -
#     work with C3 using a specific commit (6fee4b6).
#
#     For _any_ ESP32 targets, the GitHub 'main' provides automatic 'chip' detection.
#
#|cargo install probe-rs-tools --git https://github.com/probe-rs/probe-rs --rev 6fee4b6 --locked --force
cargo install probe-rs-tools --git https://github.com/probe-rs/probe-rs --locked --force  # latest 'main'

# Shell completion
#
# NOTE:
#   '~/.zfunc/' must exist; otherwise the command fails ('probe-rs' docs don't mention..)
#
install -d ~/.zfunc
probe-rs complete install

# Prepare udev rules
#
# Based on
#   -> https://probe.rs/docs/getting-started/probe-setup/#linux%3A-udev-rules
#
_RULES_SOURCE_URL=https://probe.rs/files/69-probe-rs.rules
_RULES_FN=$(basename ${_RULES_SOURCE_URL})
_RULES_TARGET=/etc/udev/rules.d/${_RULES_FN}
_RULES_TMP=/tmp/${_RULES_FN}

curl --proto '=https' --tlsv1.2 -LsSf ${_RULES_SOURCE_URL} -o ${_RULES_TMP}
sudo mv ${_RULES_TMP} ${_RULES_TARGET}

# Ideally, we'd turn those to 'root', but you might want to edit the '/etc/udev/rules.d/69-probe-rs.rules'.
# sudo chown root ${_RULES_TARGET}
# sudo chgrp root ${_RULES_TARGET}

sudo udevadm control --reload

sudo udevadm trigger

# We don't have the 'plugdev' group, so let's add it:
#   <<
#     If you're still unable to access the debug probes after following these steps, try adding your user to the
#     plugdev group.
#   <<
#
sudo usermod -a -G plugdev ${USER}

## 'git' CLI is needed, for 'probe-rs --version' to properly show version when installed with '--git' (as we do).
# Install it (can remove once we are back to using a stock 'probe-rs'). tbd.
#
sudo DEBIAN_FRONTEND=noninteractive apt install -y git

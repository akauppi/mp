#!/bin/bash
set -e

#
# Creates a Multipass VM, to be used for Rust Embedded (Embassy) development.
#
# Usage:
#   $ [XTENSA=1] [MP_NAME=xxx] [MP_PARAMS=...] [PROBE_RS_REMOTE={probe-rs@192.168.1.199}] rust+emb/prep.sh
#
# Requires:
#   - multipass
#
MY_PATH=$(dirname $0)

# By default, only RISC-V support is installed; Xtensa needs more
XTENSA=${XTENSA:-0}

MP_NAME=${MP_NAME:-rust-emb}
  # Note. '+' or '_' are NOT allowed in Multipass names (1.13; 1.14)

MP_PARAMS=${MP_PARAMS:---memory 6G --disk 18G --cpus 3}
  #
  # Note: You'll get started with 10G of disk, but adding a couple of (embedded) targets, nightly, etc. easily
  #     reaches beyond. Needing 'bindgen' and 'clang' might require 25GB.
  #
  # Data points:
  #     - Doing actual development (e.g. Embassy) has shown ~10GB to fall short.
  #     - With 'nrf-sdc' (bindgen, clang, ...) 18GB was too short.

# Wasn't able to do interactive prompt on macOS (bash 3.2), but.. this should be fine.
PROBE_RS_REMOTE=${PROBE_RS_REMOTE:-probe-rs@192.168.1.199}

CUSTOM_ENV=$MY_PATH/custom.env
CUSTOM_MOUNTS=$MY_PATH/custom.mounts.list

# If the VM is already running, decline to create. Helps us keep things simple: all initialization ever runs just once
# (automatically).
#
# tbd. Find another way to check whether a Multipass instance is running. This, without '2&>' prints some info (if it is)
#     and with '2&>' allows things to proceed. May be a glitch.
#
#     e.g. "multipass list"; skip one line; take left columns; does it have "$MP_NAME"?
#
(multipass info $MP_NAME 2>/dev/null) && {
  echo "";
  echo "The VM '${MP_NAME}' already exists. This script only creates a new instance.";
  echo "Please change the 'MP_NAME' or 'multipass delete --purge' the earlier instance.";
  echo "";
  exit 2
} >&2

# Build the foundation
#
MP_NAME="$MP_NAME" MP_PARAMS=$MP_PARAMS SKIP_SUMMARY=1 \
  ${MY_PATH}/../prep.sh

# Mount our 'linux' folder
#
# tbd. copy things to the VM, not needing the stop-mount-start delay
#
multipass stop $MP_NAME
multipass mount --type=native ${MY_PATH}/linux $MP_NAME:/home/ubuntu/.mp2
multipass start $MP_NAME

# Create '~/bin' and add to PATH (for some/any scripts to use it)
#
multipass exec $MP_NAME -- sh -c 'install -d ~/bin && echo PATH="\$PATH:$HOME/bin" >> ~/.bashrc'

multipass exec $MP_NAME -- sh -c ". .cargo/env && . ~/.mp2/rustup-targets.sh"

# 'probe-rs' remote
multipass exec $MP_NAME -- sh -c ". ~/.mp2/probe-rs-remote.sh"

# tbd. if you need it, make optional  [UNPOLISHED]
# multipass exec $MP_NAME -- sh -c ". .cargo/env && . ~/.mp2/nightly.sh"

multipass exec $MP_NAME -- sh -c "echo '\nexport PROBE_RS_REMOTE=\"$PROBE_RS_REMOTE\"' >> ~/.bashrc"

if [ -f ./linux/custom.sh ]; then
  multipass exec $MP_NAME -- sh -c ". ~/.mp2/custom.sh"
fi

multipass stop $MP_NAME
multipass umount $MP_NAME

# Append env.vars in 'custom.env' (.env syntax) to '˙~/.bashrc'.
#
# Note: Code expects no spaces in the key or value
#
# tbd. Could gather the keys together, and concatenate as a single operation (perhaps shipping the tail over as a file).
#
if [ -f $CUSTOM_ENV ]; then
  multipass exec $MP_NAME -- bash -c "echo -e '\n# From \x27$(basename $CUSTOM_ENV)\x27:' >> ~/.bashrc"

  cat $CUSTOM_ENV | grep -v "^#" | \
    xargs -I LINE multipass exec $MP_NAME -- sh -c "echo export LINE >> ~/.bashrc"
fi

# Custom mounts, as
# <<
#   # can have comments
#   ~/some/path
#   ...
# <<
if [ -f $CUSTOM_MOUNTS ]; then
  multipass stop $MP_NAME
  cat $CUSTOM_MOUNTS | grep -v "^#" | sed "s!^~!$HOME!" | \
    xargs -I X multipass mount --type=native X $MP_NAME:
fi

sleep 4

# LEAVE VM stopped; the user will likely map folders, next.
cat <<EOF

🍇 Your VM is ready.
- 'probe-rs' and 'espflash' are directed to reach '$PROBE_RS_REMOTE' over ssh.
  You can change this by editing '~/.bashrc' within the VM.
- 'ssh-copy-id $PROBE_RS_REMOTE' to make your access seamless (no pw each time!).

Next:
- Map local folders with 'multipass mount --type=native {local path} $MP_NAME:'
- Launch the VM with 'multipass shell $MP_NAME'

EOF

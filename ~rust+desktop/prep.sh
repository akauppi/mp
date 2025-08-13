#!/bin/bash
set -e

#
# Creates a Multipass VM, to be used for Rust desktop (and/or WASM) development.
#
# Usage:
#   $ [MP_NAME=xxx] [MP_PARAMS=...] rust+desktop/prep.sh
#
# Requires:
#   - multipass
#
MY_PATH=$(dirname $0)

MP_NAME=${MP_NAME:-rust-emb}
  # Note. '+' or '_' are NOT allowed in Multipass names (1.13; 1.14)

MP_PARAMS=${MP_PARAMS:---memory 6G --disk 8G --cpus 3}

# 'USE_ORIGINAL_MOUNT' is SO UNSTABLE (once the VM is up, e.g. 'multipass stop' might not work) that it's worth
# considering banning it completely. // 8-Jan-25; Multipass 1.15.0
#
USE_ORIGINAL_MOUNT=0

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
MP_NAME="$MP_NAME" MP_PARAMS=$MP_PARAMS SKIP_SUMMARY=1 USE_ORIGINAL_MOUNT=${USE_ORIGINAL_MOUNT} \
  ${MY_PATH}/../rust/prep.sh

# Mount our 'linux' folder
#
if [ "${USE_ORIGINAL_MOUNT}" == "1" ]; then
  multipass mount ${MY_PATH}/linux $MP_NAME:/home/ubuntu/.mp2
else
  multipass stop $MP_NAME
  multipass mount --type=native ${MY_PATH}/linux $MP_NAME:/home/ubuntu/.mp2
  multipass start $MP_NAME
fi

# Create '~/bin' and add to PATH (for some/any scripts to use it)
#
multipass exec $MP_NAME -- sh -c 'install -d ~/bin && echo PATH="\$PATH:$HOME/bin" >> ~/.bashrc'

#|if [ -f ./linux/custom.sh ]; then
#|  multipass exec $MP_NAME -- sh -c ". ~/.mp2/custom.sh"
#|fi

if [ "${USE_ORIGINAL_MOUNT}" == "1" ]; then
  multipass umount $MP_NAME
  multipass stop $MP_NAME
else
  multipass stop $MP_NAME
  multipass umount $MP_NAME
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

🥊 Your VM is ready.

Next:
- Map local folders with 'multipass mount --type=native {local path} $MP_NAME:'
- Launch the VM with 'multipass shell $MP_NAME'

EOF

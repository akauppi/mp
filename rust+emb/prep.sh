#!/bin/bash
set -e

#
# Creates a Multipass VM, to be used for Rust Embedded (Embassy) development.
#
# Usage:
#   $ [XTENSA=1] [MP_NAME=xxx] [MP_PARAMS=...] [USE_NATIVE_MOUNT=0|1] rust+emb/prep.sh
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
  # Note: May be more than the base 'rust' VM would use; especially disk space.
	#   Doing actual development (e.g. Embassy) has shown ~10GB to fall short.

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
  echo "The VM '${MP_NAME}' is already running. This script only creates a new instance.";
  echo "Please change the 'MP_NAME' or 'multipass delete --purge' the earlier instance.";
  echo "";
  exit 2
} >&2

# Build the foundation
#
MP_NAME="$MP_NAME" MP_PARAMS=$MP_PARAMS SKIP_SUMMARY=1 \
  ${MY_PATH}/../rust/prep.sh

# Mount our 'linux' folder
#
if [ "${USE_NATIVE_MOUNT}" != 1 ]; then  # original!
  multipass mount ${MY_PATH}/linux $MP_NAME:/home/ubuntu/.mp2
else
  multipass mount --type=native ${MY_PATH}/linux $MP_NAME:/home/ubuntu/.mp2
fi

multipass exec $MP_NAME -- sh -c ". .cargo/env && . ~/.mp2/esp.sh"
multipass exec $MP_NAME -- sh -c ". .cargo/env && . ~/.mp2/probe-rs.sh"

# tbd. if you need it, make optional  [UNPOLISHED]
# multipass exec $MP_NAME -- sh -c ". .cargo/env && . ~/.mp2/nightly.sh"

# Enable if you intend to do 'esp-rs/esp-hal' DEVELOPMENT -- not just using them (ALSO enable Xtensa support - and 'nightly') [UNPOLISHED]
#multipass exec $MP_NAME -- sh -c ". ~/.mp2/esp-rs-dev.sh"

if [ "${XTENSA}" == 1 ]; then
  multipass exec $MP_NAME -- sh -c ". ~/.mp2/espup.sh"
fi

# DOES NOT WORK in Multipass 1.14.0 #4 -> https://github.com/akauppi/mp/issues/4
# <<
#   info failed: cannot connect to the multipass socket
# <<
if [ "${USE_NATIVE_MOUNT}" != 1 ]; then
  multipass umount $MP_NAME
else
  # for now, just leave the mounts, or:
  #multipass stop $MP_NAME
  #multipass umount $MP_NAME
  true
fi

echo ""
echo "Multipass IP ($MP_NAME): $(multipass info $MP_NAME | grep IPv4 | cut -w -f 2 )"
echo ""

# Test and show the versions
multipass exec $MP_NAME -- sh -c ". .cargo/env && probe-rs --version"
  # probe-rs 0.24.0 (git commit: 6fc653a)

echo ""

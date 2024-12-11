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
  multipass stop $MP_NAME
  multipass mount ${MY_PATH}/linux $MP_NAME:/home/ubuntu/.mp2
  multipass start $MP_NAME
else
  multipass stop $MP_NAME
  multipass mount --type=native ${MY_PATH}/linux $MP_NAME:/home/ubuntu/.mp2
  multipass start $MP_NAME
fi

multipass exec $MP_NAME -- sh -c ". .cargo/env && . ~/.mp2/esp.sh"
multipass exec $MP_NAME -- sh -c ". .cargo/env && . ~/.mp2/probe-rs.sh"
multipass exec $MP_NAME -- sh -c ". ~/.mp2/usbip-drivers.sh"

# tbd. if you need it, make optional  [UNPOLISHED]
# multipass exec $MP_NAME -- sh -c ". .cargo/env && . ~/.mp2/nightly.sh"

if [ "${XTENSA}" == 1 ]; then
  multipass exec $MP_NAME -- sh -c ". ~/.mp2/espup.sh"
fi

if [ -f ~/.mp2/custom.sh ]; then
  multipass exec $MP_NAME -- sh -c ". ~/.mp2/custom.sh"
fi

# Multipass 1.14.0 absolutely NEEDS us to stop the instance first. Otherwise, following the 'umount' (in 'multipass info'):
# <<
#   info failed: cannot connect to the multipass socket
# <<
multipass stop $MP_NAME
multipass umount $MP_NAME
sleep 1
#sleep 3   # TEMP/Does this help 'start' to succeed? // '1' wasn't enough (1.14.1)
#          # NOTE: Perhaps this is due to Cloudflare WARP being active???  :)
multipass start $MP_NAME
  # ^-- THIS line has had problems:
  #   <<
  #   start failed: cannot connect to the multipass socket
  #   <<

# Clean the '/home/ubuntu/target' folder. It has ~1.2GB of build artefacts we don't need any more.
#
multipass exec $MP_NAME -- sh -c "du -h -d 1 target; rm -rf ~/target/release"
  #1.2G	target/release
  #1.2G	target

echo ""
echo "Multipass IP ($MP_NAME): $(multipass info $MP_NAME | grep IPv4 | cut -w -f 2 )"
echo ""

# Test and show the versions
multipass exec $MP_NAME -- sh -c ". .cargo/env && probe-rs --version && usbip version"
  # probe-rs 0.24.0 (git commit: ...)
  # usbip (usbip-utils 2.0)

echo ""

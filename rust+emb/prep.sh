#!/bin/bash
set -e

#
# Creates a Multipass VM, to be used for Rust Embedded (Embassy) development.
#
# Usage:
#   $ [MP_NAME=xxx] [MP_PARAMS=...] rust+emb/prep.sh
#
# Requires:
#   - multipass
#
MY_PATH=$(dirname $0)

MP_NAME=${MP_NAME:-rust-emb}
  # Note. '+' or '_' are NOT allowed in names (Multipass 1.13.1)

MP_PARAMS=${MP_PARAMS:---memory 6G --disk 18G --cpus 2}
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
MP_NAME="$MP_NAME" MP_PARAMS=$MP_PARAMS \
  SKIP_SUMMARY=1 ${MY_PATH}/../rust/prep.sh

# Mount our 'linux' folder
#
multipass mount ${MY_PATH}/linux $MP_NAME:/home/ubuntu/.mp2

# Install probe-rs
#
multipass exec $MP_NAME -- sh -c ". ~/.mp2/probe-rs.sh"

multipass umount $MP_NAME

# Maybe... something less slow would do; without this 'probe-rs' was not on the PATH. tbd.
#multipass restart $MP_NAME

echo ""
echo "Multipass IP ($MP_NAME): $(multipass info $MP_NAME | grep IPv4 | cut -w -f 2 )"
echo ""

# Test and show the versions
multipass exec $MP_NAME -- sh -c "probe-rs --version"
  #. ... tbd.

echo ""

#!/bin/bash
set -e

#
# Usage:
#   $ [MP_NAME=xxx] [MP_PARAMS=...] rust/prep.sh
#
# Requires:
#   - multipass
#
# Creates a Multipass VM, to be used for Rust development.
#
MY_PATH=$(dirname $0)

# Provide defaults
#
MP_NAME=${MP_NAME:-rust}
MP_PARAMS=${MP_PARAMS:---memory 6G --disk 12G --cpus 2}
  #
	# Disk:	3.5GB seems to be needed for Rust installation.
	#   PLENTY for RustRover remote development
	#		Must be in increments of 512M
	#
	# Hint: Use 'multipass info' on the host to observe actual usage.
	#     RustRover also has a stats display in its remote development UI.

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

# Launch and prime
#
multipass launch lts --name $MP_NAME $MP_PARAMS --mount ${MY_PATH}/linux:/home/ubuntu/.mp

multipass exec $MP_NAME -- sudo sh -c "apt update && DEBIAN_FRONTEND=noninteractive apt -y upgrade"

multipass exec $MP_NAME -- sh -c ". ~/.mp/rustup.sh"
multipass exec $MP_NAME -- sh -c ". ~/.mp/usbip-drivers.sh"

# Restarting *may* be good because of service updates
multipass restart $MP_NAME

# Even 'cargo --version' won't work unless stable|nightly is declared.
multipass exec $MP_NAME -- sh -c ". .cargo/env && rustup default stable"

echo ""
echo "Multipass IP ($MP_NAME): $(multipass info $MP_NAME | grep IPv4 | cut -w -f 2 )"
echo ""

# Test and show the versions
multipass exec $MP_NAME -- sh -c ". .cargo/env && cargo --version && rustc --version && usbip version"
  # cargo 1.75.0 (1d8b05cdd 2023-11-20)
  # rustc 1.75.0 (82e1608df 2023-12-21)
  # usbip (usbip-utils 2.0)

echo ""

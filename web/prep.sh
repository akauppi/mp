#!/bin/bash
set -e

#
# Usage:
#   $ [MP_NAME=xxx] [MP_PARAMS=...] web/prep.sh
#
# Requires:
#   - multipass
#
# Creates a Multipass VM, to be used for Web development.
#
MY_PATH=$(dirname $0)

# Provide defaults
#
MP_NAME=${MP_NAME:-web}
MP_PARAMS=${MP_PARAMS:---memory 4G --disk 5G --cpus 2}
  #
  # $ mp info web
  #   <<
  #   Disk usage:     2.1GiB out of 4.7GiB
  #   Memory usage:   178.2MiB out of 3.8GiB
  #   <<
	#
	# Hint: Use 'multipass info' on the host to observe actual usage.

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

multipass exec $MP_NAME -- sudo sh -c "DEBIAN_FRONTEND=noninteractive; apt update && apt -y upgrade"
  #
  # NOTE: This may bring up 'Newer kernel available' dialog. How to prevent that?

multipass exec $MP_NAME -- sh -c ". ~/.mp/node.sh"
multipass exec $MP_NAME -- sh -c ". ~/.mp/env.sh"
multipass exec $MP_NAME -- sh -c ". ~/.mp/gitignore.sh"

# We don't need the VM-side scripts any more.
multipass umount $MP_NAME

# Restarting *may* be good because of service updates
multipass restart $MP_NAME

echo ""
echo "Multipass IP ($MP_NAME): $(multipass info $MP_NAME | grep IPv4 | cut -w -f 2 )"
echo ""

# Test and show the versions
multipass exec $MP_NAME -- sh -c "node --version && npm --version"
  #v21.7.3
  #10.5.0

echo ""

#!/bin/bash
set -e

#
# Creates a Multipass VM, to be used for Web development.
#
# Usage:
#   $ [MP_NAME=xxx] [MP_PARAMS=...] [SKIP_SUMMARY=1] [USE_NATIVE_MOUNT=1] web/prep.sh
#
# Requires:
#   - multipass
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
(multipass info $MP_NAME >/dev/null 2>&1) && {
  echo "";
  echo "The VM '${MP_NAME}' is already running. This script only creates a new instance.";
  echo "Please change the 'MP_NAME' or 'multipass delete --purge' the earlier instance.";
  echo "";
  false
} >&2

# Launch and prime
#
if [ "${USE_NATIVE_MOUNT}" != 1 ]; then
  multipass launch lts --name $MP_NAME $MP_PARAMS --mount ${MY_PATH}/linux:/home/ubuntu/.mp
else
  multipass launch lts --name $MP_NAME $MP_PARAMS
  multipass stop $MP_NAME
  multipass mount --type=native ${MY_PATH}/linux ${MP_NAME}:/home/ubuntu/.mp
fi

multipass exec $MP_NAME -- sudo sh -c "apt update && DEBIAN_FRONTEND=noninteractive apt -y upgrade"

# Note: Changes to '.bashrc' do not need to be loaded in. When the use makes 'multipass shell', they'll get them.
#
multipass exec $MP_NAME -- sh -c "~/.mp/node.sh"
multipass exec $MP_NAME -- sh -c "~/.mp/env.sh"
multipass exec $MP_NAME -- sh -c "~/.mp/gitignore.sh"

if [ "${USE_NATIVE_MOUNT}" != 1 ]; then
  # We don't need the VM-side scripts any more.
  multipass stop $MP_NAME
  multipass umount $MP_NAME
else
  # Since we are going to be restarting, 'stop' takes no additional time.
  multipass stop $MP_NAME
  multipass umount $MP_NAME
fi

# Restart just-in-case
multipass stop $MP_NAME
multipass start $MP_NAME

if [ "${SKIP_SUMMARY}" != 1 ]; then
  echo ""
  echo "Multipass IP ($MP_NAME): $(multipass info $MP_NAME | grep IPv4 | cut -w -f 2 )"
  echo ""
fi

# Test and show the versions
multipass exec $MP_NAME -- sh -c "node --version && npm --version"
  #v22.12.0
  #10.9.0

echo ""

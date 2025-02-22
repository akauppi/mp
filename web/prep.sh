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

# Create such a file to place your time-and-again (e.g. aliases) commands (e.g. aliases):
# <<
#   alias ni='npm install'
#   alias no='npm outdated'
#   alias gs='git status'
# <<
# #undocumented
CUSTOM_BASHRC=$MY_PATH/custom.bashrc

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
  echo "The VM '${MP_NAME}' already exists. This script only creates a new instance.";
  echo "Please change the 'MP_NAME' or 'multipass delete --purge' the earlier instance.";
  echo "";
  false
} >&2

# Launch and prime
#
if [ "$USE_NATIVE_MOUNT" != "1" ]; then
  multipass launch lts --name $MP_NAME $MP_PARAMS --mount ${MY_PATH}/linux:/home/ubuntu/.mp
else
  multipass launch lts --name $MP_NAME $MP_PARAMS
  multipass stop $MP_NAME
  multipass mount --type=native ${MY_PATH}/linux ${MP_NAME}:/home/ubuntu/.mp
fi

multipass exec $MP_NAME -- sudo sh -c "apt update && DEBIAN_FRONTEND=noninteractive apt -y upgrade"

multipass exec $MP_NAME -- sh -c "~/.mp/node.sh"
multipass exec $MP_NAME -- sh -c "~/.mp/gitignore.sh"

# We don't need the VM-side scripts any more.
if [ "$USE_NATIVE_MOUNT" != "1" ]; then
  multipass umount $MP_NAME

  # Restart also for soft mounts, just-in-case
  multipass stop $MP_NAME
  multipass start $MP_NAME
else
  multipass stop $MP_NAME
  multipass umount $MP_NAME
  multipass start $MP_NAME
fi

# Append to '~/.bashrc'.
#
# All these are for the developer experience; any changes involving tools themselves would have been made above.
#
append_bashrc() {
  # for Vite hot-module-loading to work, over network mounts (which Multipass mounts are).
  LINE="export CHOKIDAR_USEPOLLING=1"
  multipass exec $MP_NAME -- sh -c "echo '$LINE' >> ~/.bashrc"

  if [ -f $CUSTOM_BASHRC ]; then
    multipass exec $MP_NAME -- bash -c "echo -e '\n# From \x27$(basename $CUSTOM_BASHRC)\x27:' >> ~/.bashrc"

    multipass transfer $CUSTOM_BASHRC $MP_NAME:tmp22
    multipass exec $MP_NAME -- sh -c "cat tmp22 >> ~/.bashrc && rm tmp22"
  fi
}
append_bashrc

#DEBUG
#multipass exec $MP_NAME -- sh -c "tail ~/.bashrc"

if [ "$SKIP_SUMMARY" != "1" ]; then
  echo ""
  echo "Multipass IP ($MP_NAME): $(multipass info $MP_NAME | grep IPv4 | cut -w -f 2 )"
  echo ""
fi

# Test and show the versions
multipass exec $MP_NAME -- sh -c "node --version && npm --version"
  #v22.14.0
  #10.9.2

echo ""

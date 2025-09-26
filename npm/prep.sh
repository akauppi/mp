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

CUSTOM_ENV=$MY_PATH/custom.env
CUSTOM_MOUNTS=$MY_PATH/custom.mounts.list

# Create such a file to place your time-and-again commands (e.g. aliases):
# <<
#   alias ni='npm install'
#   alias no='npm outdated'
#   alias nus='npm update --save'
#   alias gs='git status'
# <<
# #undocumented
CUSTOM_BASHRC=$MY_PATH/custom.bashrc

# Provide defaults
#
# Note: Keep an eye on the disk usage. Don't let free space get (much) below 1GB. If it does, 'npm install' etc. starts
#       to misbehave, and it DOES NOT necessarily mention lack of disk space as the root cause!!
#
MP_NAME=${MP_NAME:-npm}
MP_PARAMS=${MP_PARAMS:---memory 4G --disk 8G --cpus 2}
  #
	# Note:
	#   - 7G disk wasn't enough (with two npm-using projects, Playwright and 'wrangler'). 20-Sep-25
	#
	#         ~/.npm                  => 3GB    <--- REDUCES BY 2GB by 'npm cache verify'
	#         ~/.node_modules cache   => ca. 200MB / project
	#         ~/.cache
	#             /ms-playwright      => 326MB
	#         ~/.npm-packages         => 200MB
	#
	#   <<
	#     $ npm cache verify
  #     Cache verified and compressed (~/.npm/_cacache)
  #     Content verified: 1271 (916647549 bytes)
  #     Content garbage-collected: 877 (2171927570 bytes)   <<--- 2.1GB reclaimed
  #     Index entries: 1271
  #     Finished in 17.519s
	#   <<
	#
  # $ mp info npm
  #   <<
  #   Disk usage:     2.2GiB out of 4.7GiB
  #   Memory usage:   402.4MiB out of 3.8GiB
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
if [ "$USE_NATIVE_MOUNT" == "1" ]; then
  multipass launch lts --name $MP_NAME $MP_PARAMS
  multipass stop $MP_NAME
  multipass mount --type=native ${MY_PATH}/linux ${MP_NAME}:/home/ubuntu/.mp
else
  multipass launch lts --name $MP_NAME $MP_PARAMS --mount ${MY_PATH}/linux:/home/ubuntu/.mp
fi

multipass exec $MP_NAME -- sudo sh -c "apt update && DEBIAN_FRONTEND=noninteractive apt -y upgrade"

multipass exec $MP_NAME -- sh -c "~/.mp/node.sh"
multipass exec $MP_NAME -- sh -c "~/.mp/gitignore.sh"

# We don't need the VM-side scripts any more.
if [ "$USE_NATIVE_MOUNT" == "1" ]; then
  multipass stop $MP_NAME
  multipass umount $MP_NAME
  multipass start $MP_NAME
else
  multipass umount $MP_NAME

  # Restart also for soft mounts, just-in-case
  multipass stop $MP_NAME
  multipass start $MP_NAME
fi

# Append to '~/.bashrc'.
#
# These are for the developer experience; any changes involving tools themselves would have been made above.
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

# Append env.vars in 'custom.env' (.env syntax) to '˙~/.bashrc'.
#
# Note: Code expects no spaces in the key or value
#
# tbd. Could gather the keys together, and concatenate as a single operation (perhaps shipping the tail over as a file).
#   For now, we only use this for a single token API, so..
#
# tbd. Also, should "print"-something the lines so that no harmful tricks can be made (no newline allowed). However,
#   that would be the user shooting themselves in the feet, so...
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
  multipass start $MP_NAME
fi

if [ "$SKIP_SUMMARY" != "1" ]; then
  echo ""
  echo "Multipass IP ($MP_NAME): $(multipass info $MP_NAME | grep IPv4 | cut -w -f 2 )"
  echo ""
fi

# Test and show the versions
multipass exec $MP_NAME -- sh -c "node --version && npm --version"
  #v24.1.0
  #11.3.0

echo ""

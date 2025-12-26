#!/bin/bash
set -e

#
# Creates a Multipass VM, to be used for Rust development.
#
# Usage:
#   $ [MP_NAME=xxx] [MP_PARAMS=...] [SKIP_SUMMARY=1] rust/prep.sh
#
# Requires:
#   - multipass
#
MY_PATH=$(dirname $0)

# Provide defaults
#
MP_NAME=${MP_NAME:-rust}
MP_PARAMS=${MP_PARAMS:---memory 6G --disk 10G --cpus 3}
  #
	# Disk:	2.5GB used after installation.
	#   However.. doing actual development has shown 10GB to fall short (tbd. non-embedded examples..?).
	#   If you were to use RustRover remote development, PLENTY of additional disk space is needed. (just... DON'T DO IT)
	#		Must be in increments of 512M

if [ "${SKIP_SUMMARY}" != 1 ]; then
  CUSTOM_ENV=$MY_PATH/custom.env
  CUSTOM_MOUNTS=$MY_PATH/custom.mounts.list
else
  # Called from 'rust-emb' - let it set up the custom env + mounts
  CUSTOM_ENV=
  CUSTOM_MOUNTS=
fi

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
multipass launch lts --name $MP_NAME $MP_PARAMS
multipass stop $MP_NAME
multipass mount --type=native ${MY_PATH}/linux ${MP_NAME}:/home/ubuntu/.mp

multipass exec $MP_NAME -- sudo sh -c "apt update && DEBIAN_FRONTEND=noninteractive apt -y upgrade"

multipass exec $MP_NAME -- sh -c ". ~/.mp/rustup.sh"
multipass exec $MP_NAME -- sh -c ". .cargo/env && . ~/.mp/rustfmt.sh"

# Use common '~/target' for artefacts of all projects. Saves disk space and _more importantly_ guarantees the
# artefacts faster access than if they were mounted!!
multipass exec $MP_NAME -- sh -c ". ~/.mp/shared-target.sh"

# We don't need the VM-side scripts any more; leave stopped.
multipass stop $MP_NAME
multipass umount $MP_NAME

# Append env.vars in 'custom.env' (.env syntax) to '˙~/.bashrc'.
#
# Note: Code expects no spaces in the key or value
#
# tbd. Could gather the keys together, and concatenate as a single operation (perhaps shipping the tail over as a file).
#
if [[ -f $CUSTOM_ENV ]]; then
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
if [[ -f $CUSTOM_MOUNTS ]]; then
  multipass stop $MP_NAME
  cat $CUSTOM_MOUNTS | grep -v "^#" | sed "s!^~!$HOME!" | \
    xargs -I X multipass mount --type=native X $MP_NAME:
fi

multipass start $MP_NAME

# Needs VM to be running
if [ "${SKIP_SUMMARY}" != 1 ]; then
  echo ""
  echo "Multipass IP ($MP_NAME): $(multipass info $MP_NAME | grep IPv4 | cut -w -f 2 )"
  echo ""
fi

# Test and show the versions
multipass exec $MP_NAME -- sh -c ". .cargo/env && cargo --version && rustc --version"
  # cargo 1.92.0 (344c4567c 2025-10-21)
  # rustc 1.92.0 (ded5c06cf 2025-12-08)

echo ""

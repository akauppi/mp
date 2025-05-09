#!/bin/bash
set -e

#
# Creates a Multipass VM, to be used for Rust development.
#
# Usage:
#   $ [MP_NAME=xxx] [MP_PARAMS=...] [SKIP_SUMMARY=1] [USE_ORIGINAL_MOUNT=1] rust/prep.sh
#
# Requires:
#   - multipass
#
MY_PATH=$(dirname $0)

# Provide defaults
#
MP_NAME=${MP_NAME:-rust}
MP_PARAMS=${MP_PARAMS:---memory 6G --disk 10G --cpus 2}
  #
	# Disk:	3.5GB seems to be needed for Rust installation.
	#   However.. doing actual development (e.g. Embassy) has shown ~10GB to fall short.
	#   Equally, if you were to use RustRover remote development, PLENTY of additional disk space is needed.
	#		Must be in increments of 512M
	#
	# Hint: Use 'multipass info' on the host to observe actual usage.
	#     RustRover also has a stats display in its remote development UI.

USE_ORIGINAL_MOUNT=${USE_ORIGINAL_MOUNT:-0}

# DISABLED
#|CUSTOM_MOUNTS=${CUSTOM_MOUNTS:-$MY_PATH/custom.mounts.list}   # 0|{path}

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
if [ "${USE_ORIGINAL_MOUNT}" == "1" ]; then
  multipass launch lts --name $MP_NAME $MP_PARAMS --mount ${MY_PATH}/linux:/home/ubuntu/.mp
else
  multipass launch lts --name $MP_NAME $MP_PARAMS
  multipass stop $MP_NAME
  multipass mount --type=native ${MY_PATH}/linux ${MP_NAME}:/home/ubuntu/.mp
fi

multipass exec $MP_NAME -- sudo sh -c "apt update && DEBIAN_FRONTEND=noninteractive apt -y upgrade"

multipass exec $MP_NAME -- sh -c ". ~/.mp/rustup.sh"
multipass exec $MP_NAME -- sh -c ". .cargo/env && . ~/.mp/rustfmt.sh"

# Use common '~/target' for artefacts of all projects. Saves disk space and _more importantly_ guarantees the
# artefacts faster access than if they were mounted!!
multipass exec $MP_NAME -- sh -c ". ~/.mp/shared-target.sh"

# We don't need the VM-side scripts any more; leave stopped.
if [ "${USE_ORIGINAL_MOUNT}" == "1" ]; then
  multipass umount $MP_NAME
  multipass stop $MP_NAME
else
  multipass stop $MP_NAME
  multipass umount $MP_NAME
fi

# DISABLED; use 'rust+{desktop|emb}'
#|# Custom mounts, as
#|# <<
#|#   # can have comments
#|#   ~/some/path
#|#   ...
#|# <<
#|if [[ "$CUSTOM_MOUNTS" != "0" ]] && [[ -f $CUSTOM_MOUNTS ]]; then
#|  multipass stop $MP_NAME
#|  cat $CUSTOM_MOUNTS | grep -v "^#" | sed "s!^~!$HOME!" | \
#|    xargs -I X multipass mount --type=native X $MP_NAME:
#|fi

multipass start $MP_NAME

# Needs VM to be running
if [ "${SKIP_SUMMARY}" != 1 ]; then
  echo ""
  echo "Multipass IP ($MP_NAME): $(multipass info $MP_NAME | grep IPv4 | cut -w -f 2 )"
  echo ""
fi

# Test and show the versions
multipass exec $MP_NAME -- sh -c ". .cargo/env && cargo --version && rustc --version"
  # cargo 1.85.0 (d73d2caf9 2024-12-31)
  # rustc 1.85.0 (4d91de4e4 2025-02-17)

echo ""

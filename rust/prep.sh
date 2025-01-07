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

multipass exec $MP_NAME -- sh -c ". ~/.mp/shared-target.sh"

# We don't need the VM-side scripts any more.
if [ "${USE_ORIGINAL_MOUNT}" == "1" ]; then
  multipass umount $MP_NAME
else
  multipass stop $MP_NAME
  multipass umount $MP_NAME
  multipass start $MP_NAME
fi

# Restarting *may* be good because of service updates. Takes a little time, but it's just one time.
# <<
#   Service restarts being deferred:
#    /etc/needrestart/restart.d/dbus.service
#    systemctl restart getty@tty1.service
#    systemctl restart serial-getty@ttyS0.service
#    systemctl restart systemd-logind.service
#    systemctl restart unattended-upgrades.service
#
#   No containers need to be restarted.
# <<
# <<
#   User sessions running outdated binaries:
#    ubuntu @ session #17: sshd[2214]
#    ubuntu @ session #18: sshd[2816]
#    ubuntu @ user manager service: systemd[1066]
# <<
if [ "${USE_ORIGINAL_MOUNT}" == "1" ]; then   # native mount did it already, above
  multipass stop $MP_NAME
  multipass start $MP_NAME
fi

if [ "${SKIP_SUMMARY}" != 1 ]; then
  echo ""
  echo "Multipass IP ($MP_NAME): $(multipass info $MP_NAME | grep IPv4 | cut -w -f 2 )"
  echo ""
fi

# Test and show the versions
multipass exec $MP_NAME -- sh -c ". .cargo/env && cargo --version && rustc --version"
  # cargo 1.80.1 (376290515 2024-07-16)
  # rustc 1.80.1 (3f5fd8dd4 2024-08-06)

echo ""

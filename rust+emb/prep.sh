#!/bin/bash
set -e

#
# Creates a Multipass VM, to be used for Rust Embedded (Embassy) development.
#
# Usage:
#   $ [XTENSA=1] [MP_NAME=xxx] [MP_PARAMS=...] [USE_NATIVE_MOUNT=1] [PROBE_RS_REMOTE={probe-rs@192.168.1.199}] rust+emb/prep.sh
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

# Wasn't able to do interactive prompt on macOS (bash 3.2), but.. this should be fine.
PROBE_RS_REMOTE=${PROBE_RS_REMOTE:-probe-rs@192.168.1.199}

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
if [ "${USE_NATIVE_MOUNT}" != "1" ]; then  # original!
  multipass stop $MP_NAME
  multipass mount ${MY_PATH}/linux $MP_NAME:/home/ubuntu/.mp2
  multipass start $MP_NAME
else
  multipass stop $MP_NAME
  multipass mount --type=native ${MY_PATH}/linux $MP_NAME:/home/ubuntu/.mp2
  multipass start $MP_NAME
fi

# Create '~/bin' and add to PATH (for some/any scripts to use it)
#
multipass exec $MP_NAME -- sh -c 'install -d ~/bin && echo PATH="$PATH:$HOME/bin" >> ~/.bashrc'

multipass exec $MP_NAME -- sh -c ". .cargo/env && . ~/.mp2/esp.sh"

# 'probe-rs' remote
multipass exec $MP_NAME -- sh -c ". ~/.mp2/probe-rs-remote.sh"

# 'probe-rs' over USB/IP
#multipass exec $MP_NAME -- sh -c ". .cargo/env && . ~/.mp2/probe-rs.sh"
#multipass exec $MP_NAME -- sh -c ". ~/.mp2/usbip-drivers.sh"

# tbd. if you need it, make optional  [UNPOLISHED]
# multipass exec $MP_NAME -- sh -c ". .cargo/env && . ~/.mp2/nightly.sh"

if [ "${XTENSA}" == 1 ]; then
  multipass exec $MP_NAME -- sh -c ". ~/.mp2/espup.sh"
fi

multipass exec $MP_NAME -- sh -c "echo '\nexport PROBE_RS_REMOTE=\"$PROBE_RS_REMOTE\"' >> ~/.bashrc"

if [ -f ~/.mp2/custom.bashrc.sh ]; then
  multipass exec $MP_NAME -- sh -c "cat ~/.mp2/custom.bashrc.sh >> ~/.bashrc"
fi

# Disabled (7-Jan-25): only '4.0K' reported (since we don't build 'probe-rs', any more)
#|# Clean the '/home/ubuntu/target' folder. It has ~1.2GB of build artefacts we don't need any more.
#|#
#|multipass exec $MP_NAME -- sh -c "du -h -d 1 target; rm -rf ~/target/release"
#|  #1.2G	target/release
#|  #1.2G	target

# Multipass 1.14.0 absolutely NEEDS us to stop the instance first. Otherwise, following the 'umount' (in 'multipass info'):
# <<
#   info failed: cannot connect to the multipass socket
# <<
#multipass stop $MP_NAME
multipass umount $MP_NAME
sleep 4

# LEAVE VM stopped; the user will likely map folders, next.
cat <<EOF

🍇 Your VM is ready.
- 'probe-rs' is directed to reach '$PROBE_RS_REMOTE' over ssh.
  You can change this by editing '~/.bashrc' within the VM.

Next:
- Map local folders with 'multipass mount --type=native {local path} $MP_NAME:/home/ubuntu/{remote path}'
- Launch the VM with 'multipass shell $MP_NAME'

EOF

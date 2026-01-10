#!/bin/bash
set -e

#
# Creates a Multipass VM, to be used for Rust Embedded (Embassy) development.
#
# Usage:
#   $ [XTENSA=1] [MP_NAME=xxx] [MP_PARAMS=...] [PROBE_RS_REMOTE={probe-rs@192.168.1.199}] rust/+emb/prep.sh
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
  # Note: You'll get started with 10G of disk, but adding a couple of (embedded) targets, nightly, etc. easily
  #     reaches beyond. Needing 'bindgen' and 'clang' might require 25GB.
  #
  # Data points:
  #     - Doing actual development (e.g. Embassy) has shown ~10GB to fall short.
  #     - With 'nrf-sdc' (bindgen, clang, ...) 18GB was too short.

# Wasn't able to do interactive prompt on macOS (bash 3.2), but.. this should be fine.
PROBE_RS_REMOTE=${PROBE_RS_REMOTE:-probe-rs@192.168.1.199}

CUSTOM_ENV=$MY_PATH/custom.env
CUSTOM_MOUNTS=$MY_PATH/custom.mounts.list

# Build the foundation
#
MP_NAME="$MP_NAME" MP_PARAMS=$MP_PARAMS SKIP_SUMMARY=1 \
  ${MY_PATH}/../_base/prep.sh

multipass transfer -rp ${MY_PATH}/linux ${MP_NAME}:/home/ubuntu/.mp2

# Create '~/bin' and add to PATH (for some/any scripts to use it)
#
multipass exec $MP_NAME -- sh -c 'install -d ~/bin && echo PATH="\$PATH:$HOME/bin" >> ~/.bashrc'

multipass exec $MP_NAME -- sh -c ". .cargo/env && . ~/.mp2/rustup-targets.sh"

# 'probe-rs' remote
multipass exec $MP_NAME -- sh -c ". ~/.mp2/probe-rs-remote.sh"

multipass exec $MP_NAME -- sh -c "echo '\nexport PROBE_RS_REMOTE=\"$PROBE_RS_REMOTE\"' >> ~/.bashrc"

if [ -f ${MY_PATH}/linux/custom.sh ]; then
  multipass exec $MP_NAME -- sh -c ". ~/.mp2/custom.sh"
fi

multipass exec $MP_NAME -- sh -c "rm -rf .mp2"

# Polish
MP_NAME="$MP_NAME" \
  CUSTOM_ENV=$CUSTOM_ENV \
  CUSTOM_MOUNTS=$CUSTOM_MOUNTS \
  ${MY_PATH}/../_base/polish.sh

cat <<EOF

🍇 Your VM is ready.
- 'probe-rs' and 'espflash' are directed to reach '$PROBE_RS_REMOTE' over ssh.
  You can change this by editing '~/.bashrc' within the VM.
- 'ssh-copy-id $PROBE_RS_REMOTE' to make your access seamless (no pw each time!).

Next:
- Map local folders with 'multipass mount --type=native {local path} $MP_NAME:'
- Launch the VM with 'multipass shell $MP_NAME'

EOF

#!/bin/bash
set -e

#
# Creates a Multipass VM, to be used for Rust WASM (for browser) development.
#
# Usage:
#   $ [MP_NAME=xxx] [MP_PARAMS=...] rust/+wasm/prep.sh
#
# Requires:
#   - multipass
#
MY_PATH=$(dirname $0)

# Provide defaults
#
MP_NAME=${MP_NAME:-rust-wasm}
MP_PARAMS=${MP_PARAMS:---memory 6G --disk 8G --cpus 3}
  #
	# Disk:	3.2GB used after installation.
	#   However.. doing actual development has shown 10GB to fall short (tbd. are there NON-EMBEDDED examples..?).

CUSTOM_ENV=$MY_PATH/custom.env
CUSTOM_MOUNTS=$MY_PATH/custom.mounts.list

# Build the foundation
#
MP_NAME=$MP_NAME MP_PARAMS=$MP_PARAMS SKIP_SUMMARY=1 \
  ${MY_PATH}/../_base/prep.sh

multipass transfer -rp ${MY_PATH}/linux ${MP_NAME}:/home/ubuntu/.mp3

# Install 'clang'. Desktop packages often need it.
#
multipass exec $MP_NAME -- sudo sh -c "apt install -y clang"

multipass exec $MP_NAME -- sh -c ". .cargo/env && . ~/.mp3/rustup-targets.sh"

multipass exec $MP_NAME -- sh -c "rm -rf .mp3"

# Polish
MP_NAME="$MP_NAME" \
  CUSTOM_ENV=$CUSTOM_ENV \
  CUSTOM_MOUNTS=$CUSTOM_MOUNTS \
  ${MY_PATH}/../_base/polish.sh

# Test and show WASM-relevant versions (these are just placehoders tbd.)
multipass exec $MP_NAME -- sh -c ". .cargo/env && cargo --version && rustc --version"
  # cargo 1.92.0 (344c4567c 2025-10-21)
  # rustc 1.92.0 (ded5c06cf 2025-12-08)

echo ""

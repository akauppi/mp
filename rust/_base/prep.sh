#!/bin/bash
set -e

#
# Creates a Multipass VM, to be used for Rust development.
#
# Usage:
#   $ [MP_NAME=xxx] [MP_PARAMS=...] rust/_base/prep.sh
#
# Requires:
#   - multipass
#
MY_PATH=$(dirname $0)

# DO NOT provide a default for the name: this is intended to be used via the "flavours".
#
[[ -nz "${MP_NAME}" ]] || (
  echo >&2 "Please provide 'MP_NAME' env.var. explicitly"; false
)
#MP_NAME=${MP_NAME}

MP_PARAMS=${MP_PARAMS:-}

# If the VM is already running, decline to create. Helps us keep things simple: all initialization ever runs just once
# (automatically).
#
# tbd. Find another way to check whether a Multipass instance is running. This, without '2>/dev/null' prints some info (if it is)
#     and with '>&2' allows things to proceed. May be a glitch.
#
(multipass info $MP_NAME 2>/dev/null) && {
  echo "";
  echo "The VM '${MP_NAME}' is already running. This script only creates a new instance.";
  echo "Please change the 'MP_NAME' or 'multipass delete --purge' the earlier instance.";
  echo "";
  false
} >&2

# Launch and prime
#
multipass launch lts --name $MP_NAME $MP_PARAMS

multipass transfer -rp ${MY_PATH}/linux ${MP_NAME}:/home/ubuntu/.mp

multipass exec $MP_NAME -- sudo sh -c "apt update && DEBIAN_FRONTEND=noninteractive apt -y upgrade"

multipass exec $MP_NAME -- sh -c ". ~/.mp/rustup.sh"
multipass exec $MP_NAME -- sh -c ". .cargo/env && . ~/.mp/rustfmt.sh"

# Use common '~/target' for artefacts of all projects. Saves disk space and _more importantly_ guarantees the
# artefacts faster access than if they were mounted!!
multipass exec $MP_NAME -- sh -c ". ~/.mp/shared-target.sh"

# We don't need the VM-side scripts any more
multipass exec $MP_NAME -- sh -c "rm -rf .mp"

# Test and show the versions
multipass exec $MP_NAME -- sh -c ". .cargo/env && cargo --version && rustc --version"
  # cargo 1.92.0 (344c4567c 2025-10-21)
  # rustc 1.92.0 (ded5c06cf 2025-12-08)

echo ""

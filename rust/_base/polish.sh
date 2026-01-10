#!/bin/bash
set -e

#
# Final touches to a Multipass VM
#
# Usage:
#   $ MP_NAME=... [CUSTOM_ENV={path}] [CUSTOM_MOUNTS={path}] rust/_base/polish.sh
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

# CUSTOM_ENV    {path-to}/custom.env
# CUSTOM_MOUNTS {path-to}/custom.mounts.list

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
  # tbd. better error recovery here: if 'X' folder does not exist, give a WARNING but carry on with the rest;
  #     currently fails the entire script.

multipass start $MP_NAME

echo ""

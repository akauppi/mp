#!/bin/bash
set -e

#
# Creates a Multipass VM, to be used for Cloudflare Web development.
#
# Usage:
#   $ [MP_NAME=xxx] [MP_PARAMS=...] web+cf/prep.sh
#
# Requires:
#   - multipass
#
MY_PATH=$(dirname $0)

CUSTOM_ENV=$MY_PATH/custom.env
CUSTOM_MOUNTS=$MY_PATH/custom.mounts.list

# Provide defaults
#
MP_NAME=${MP_NAME:-web-cf}
  # Note. 'web+cf' or 'web_cf' not allowed names by Multipass (1.13.1)

MP_PARAMS=${MP_PARAMS:---memory 4G --disk 8G --cpus 2}
  #
  # $ mp info web-cf
  #   <<
  #   Disk usage:     2.6 GiB out of 4.8 GiB
  #   Memory usage:   180 MiB out of 3.8 GiB
  #   <<
	#
	# Hint: Use 'multipass info' on the host to observe actual usage.
	#
	# NOTE! Updating 'wrangler' with 'npm install -g wrangler' needs around 1GB headroom.
	#       Failed when 3.9 / 4.8 GB used. => lifting the limit

# If the VM is already running, decline to create. Helps us keep things simple: all initialization ever runs just once
# (automatically).
#
(multipass info $MP_NAME >/dev/null 2>&1) && {
  echo "";
  echo "The VM '${MP_NAME}' already exists. This script only creates a new instance.";
  echo "Please change the 'MP_NAME' or 'multipass delete --purge' the earlier instance.";
  echo "";
  exit 2
} >&2

# Build the foundation
#
SKIP_SUMMARY=1 MP_NAME="$MP_NAME" MP_PARAMS=$MP_PARAMS ${MY_PATH}/../web/prep.sh

# Install wrangler CLI
#
multipass exec $MP_NAME -- sh -c "npm install -g wrangler"

echo ""
echo "Multipass IP ($MP_NAME): $(multipass info $MP_NAME | grep IPv4 | cut -w -f 2 )"
echo ""

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

#DEBUG
#multipass exec $MP_NAME -- sh -c "tail ~/.bashrc"

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

# Test and show the versions
#
# Note: 'bash -i' is needed to have '~/.bashrc' read (and 'wrangler' visible in PATH).
#     Alternative: 'sh -c "npx wrangler version"'
#
multipass exec $MP_NAME -- bash -c -i "wrangler --version"
  # ⛅️ wrangler 3.109.1
  #--------------------

echo ""

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
OMIT_SUMMARY=1 MP_NAME="$MP_NAME" MP_PARAMS=$MP_PARAMS ${MY_PATH}/../web/prep.sh

# Install wrangler CLI
#
multipass exec $MP_NAME -- sh -c "npm install -g wrangler"

# tbd. foundation could have a 'quiet' flag
#
echo ""
echo "Multipass IP ($MP_NAME): $(multipass info $MP_NAME | grep IPv4 | cut -w -f 2 )"
echo ""

# Test and show the versions
#
# Note: 'bash -i' is needed to have '~/.bashrc' read (and 'wrangler' visible in PATH).
#     Alternative: 'sh -c "npx wrangler version"'
#
multipass exec $MP_NAME -- bash -c -i "wrangler --version"
  # ⛅️ wrangler 3.60.3
  #-------------------

echo ""

#!/bin/bash
set -e

#
# Presuming 'web-cf' VM is running, helps you to login with the CLI.
#
# This script is for MANUAL USE in setting up 'wrangler' CLI; not referred to from other scripts!!!
#
# Usage:
#   $ [MP_NAME=xxx] web+cf/login-fwd.sh
#
MY_PATH=$(dirname $0)
_PORT=8976

# Name same as in 'prep.sh'
#
MP_NAME=${MP_NAME:-web-cf}
  # Note. 'web+cf' or 'web_cf' not allowed names by Multipass (1.13.1)

# Require the VM to be already running.
#
(multipass info $MP_NAME >/dev/null 2>&1) || {
  echo "";
  echo "Expecting VM '${MP_NAME}' to be running, but it isn't. Please run '${MY_PATH}/prep.sh'.";
  echo "";
  exit 2
} >&2

_MSG="*
* Port is now forwarded.
* Please
*   - run 'wrangler login --browser=false' in the VM
*   - open the provided link in a browser you use with Cloudflare
*   - sign in
*
* Once the CLI is happy (you may try 'wrangler whoami'), press a key and we'll close the port forward.
*"

PORT=${_PORT} MP_NAME=${MP_NAME} MSG="${_MSG}" ${MY_PATH}/../tools/port-fwd.sh

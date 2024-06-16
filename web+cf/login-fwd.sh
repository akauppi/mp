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
LOGIN_PORT=8976

_ID_RSA=/var/root/Library/Application\ Support/multipassd/ssh-keys/id_rsa

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

# Pick the IP
#
_MP_IP=$(multipass info $MP_NAME | grep IPv4 | cut -w -f 2 )

# tbd. the prompts should use some COLOR.
cat <<EOL1
*
* Going to forward the port '${_MP_IP}:${LOGIN_PORT}' as 'localhost:${LOGIN_PORT}' so the dance can begin.
*
* This will require a 'sudo' pw next.
*
EOL1
read -rsp $'Press a key to continue...\n' -n1 KEY

# Expose port used by 'wrangler login' (in the VM) to the host.
#
# Note: To access the 'id_rsa' file (which needs 'sudo' and contains a space in the path in macOS), 'sh -c' is required.
# sudo sh -c "ls -al \"${_ID_RSA}\""   # ok
#
sudo -b sh -c "ssh -ntt -i \"${_ID_RSA}\" -o StrictHostKeyChecking=accept-new -L ${LOGIN_PORT}:localhost:${LOGIN_PORT} ubuntu@${_MP_IP}" >/dev/null
  #
  # Note: '-ntt' needed for running ssh in background (takes input from /dev/null).
  # Note 2: '-o Strict...=accept-new' so that it won't ask you interactively for further permission.

# Note: Cannot use '$!' to get the pid of that process (because "sudo -b"?), so we grep instead.
_PID_TO_KILL=$(ps -a | grep sudo | grep "ubuntu@${_MP_IP}" | sed 's/^ *//' | cut -w -f 1)
  # 92024

# exit hook to not keep the port open
hook() {
  kill ${_PID_TO_KILL}
}
trap hook EXIT

# Ask the user to do the login. This way they see the URL best in the VM.
#
cat <<EOL
*
* Port is now forwarded.
* Please
*   - run 'wrangler login --browser=false' in the VM
*   - open the provided link in a browser you use with Cloudflare
*   - sign in
*
* Once the CLI is happy (you may try 'wrangler whoami'), press a key and we'll close the port forward.
*
EOL
read -rsp $'Press a key once login dance is over...\n' -n1 KEY

echo ""

#!/bin/bash
set -e

# Launch a Multipass VM so that port '$PORT' is forwarded to the host.
#
# Usage:
#   $ PORT=3000,3123 host-tools/launch.sh
#
# Notes:
#   After updates of Multipass, the key may have changed. Just remove the `~/.mp.key` and recreate it (as the script
#   instructs).   // tbd. detect the situation when the key is wrong???
#
# References:
#   - "Specify private key in SSH as string" (SO) [1]
#     -> https://stackoverflow.com/questions/12041688/specify-private-key-in-ssh-as-string
#
MP_NAME=${MP_NAME:-npm}

_KEY=/var/root/Library/Application\ Support/multipassd/ssh-keys/id_rsa
_LOCAL_KEY=$HOME/.mp.key

bold=$(printf '\033[1m')
unbold=$(printf '\033[21m')

usage() {
  echo >&2 "Usage:
  $ PORT=3000,3123[,...] [MP_NAME=...] $0
"
}

if [[ -z "$PORT" ]]; then
  usage
  false
fi

# Expect to find '~/.mp.key' which allows ssh to the Multipass instances.
#
if [[ ! -f $_LOCAL_KEY ]]; then
  echo >&2 "
  To use this script, you need to provide a _user_space_ copy of the key Multipass uses between the host and VM's
  at $_LOCAL_KEY. It's currently not there.

  Execute the commands below. Leaving the otherwise hidden (needing sudo) key there should be fine; it cannot be reached
  by outside parties, anyways. And you can remove the copy after port forwarding is no longer necessary.

  If you dislike the idea altogether, you can still make some other workflow alongside this template.

  ${bold}sudo cp $(printf %q "$_KEY") $_LOCAL_KEY${unbold}
  ${bold}sudo chown $USER $_LOCAL_KEY${unbold}
  ${bold}chmod 600 $_LOCAL_KEY${unbold}
"
  false
fi

# Launch. Without this, it doesn't have an IP; nor can we test the validity of the cached key.
multipass start $MP_NAME

# Pick the IP
_MP_IP=$(multipass info $MP_NAME | grep IPv4 | cut -w -f 2 )

# Check whether '~/.mp.key' is still valid.
#
# Note: We cannot simply diff the keys, because haven't access to the original key. However, if we launch the VM and
#     try to reach it with the cached key, it will fail if the key isn't valid (any more).
#

# Ensure the key is valid
#
#   tbd. fully uninstall Multipass (keep the cached key)
#       - re-install; has the original key changed?
#       - launch; do we see the error?
#
ssh -i ${_LOCAL_KEY} -o StrictHostKeyChecking=accept-new ubuntu@${_MP_IP} whoami > /dev/null || (
  echo >&2 "
  Local MP key doesn't seem to work. Please re-cache it by removing (rm ${_LOCAL_KEY}) and re-running
  this command, for instructions. This may be due to Multipass having been updated.
"
  false
)

# For each port, add '-L {port}:localhost:{port}' parameter
_PORT_PARAMS=
for p in ${PORT//,/ }
do
  _PORT_PARAMS="-L $p:localhost:$p ${_PORT_PARAMS}"
    # reversed order doesn't matter
done

# Note:
#   -E: "Append debug logs to log_file instead of standard error". Without it, the console gets dumped with
#       <<
#         channel 3: open failed: connect failed: Connection refused
#       <<
#       ..once you stop the service (e.g. 'npm run dev') within the VM. We want the forward to pick up again, if there's
#       anyone answering that port within VM. And doing this quietly!
#
ssh -ntt -i ${_LOCAL_KEY} -o StrictHostKeyChecking=accept-new -E /dev/null ${_PORT_PARAMS} ubuntu@${_MP_IP} > /dev/null &
_PS_TO_KILL=$!
  # The process now runs in the background, and we have its id.

cleanup() {
  kill ${_PS_TO_KILL}
}

#|cat <<EOL1
#|*
#|* Forwarding the port(s) '${PORT}' as 'localhost'. (ps id ${_PS_TO_KILL})
#|*
#|EOL1

# Launch the Multipass shell
multipass shell ${MP_NAME}

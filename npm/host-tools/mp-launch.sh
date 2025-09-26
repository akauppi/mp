#!/bin/bash
set -e

# tbd. Change approach to what worked with 'FY/website'. AK30-Aug-25

# See a service running within Multipass VM as 'localhost' on the host.
#
# Note: This is ONLY A MATTER OF CONVENIENCE. You can always point the browser to the full '{ip}:{port}' URL.
#     Also, if the assumptions done in this script are not to your liking, you can easily pick the commands and
#     perform similar actions manually - the way You like! :)
#
# Usage:
#   $ PORT=x[,y] [MP_NAME=...] [MSG="...\n..."] {path-to}/port-fwd.sh [-d]
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

_DAEMON=''
if [[ "$1" == "-d" ]]; then
  _DAEMON=1
fi

usage() {
  echo >&2 "Usage:
  $ PORT=... [MP_NAME=...] $0 [-d]
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

#DISABLED (see above)
# Limit rights, ssh likes it as 600.
#
#chmod 600 $_LOCAL_KEY

# Pick the IP
_MP_IP=$(multipass info $MP_NAME | grep IPv4 | cut -w -f 2 )

#cat <<EOL1
#*
#* Going to forward the port '${_MP_IP}:${PORT}' as 'localhost:${PORT}'.
#*
#EOL1

# For each port, add '-L {port}:localhost:{port}' parameter
_PORT_PARAMS=
for p in ${PORT//,/ }
do
  _PORT_PARAMS="-L $p:localhost:$p ${_PORT_PARAMS}"
    # reversed order doesn't matter
done

ssh -ntt -i ${_LOCAL_KEY} -o StrictHostKeyChecking=accept-new ${_PORT_PARAMS} ubuntu@${_MP_IP} > /dev/null &
_PS_TO_KILL=$!
  # The process now runs in the background, and we have its id.

cleanup() {
  kill ${_PS_TO_KILL}
}

if [[ ! $_DAEMON ]]; then
  trap cleanup EXIT

  # '../web+cf/sh/login-fwd.sh' benefits from being able to inject a custom message.
  #
  MSG=${MSG:-"\nSeeing port(s) ${PORT}. KEEP THIS TERMINAL RUNNING.\n"}
  echo -e "${MSG}"
    # ^-- Quotes matter for proper output of ('web+cf/.../login-fwd.sh's) message. Do not remove.

  read -rsp $'Press a key to stop the sharing.\n' -n1 KEY
else
  echo "Seeing port(s) ${PORT}.

To stop sharing, do ${bold}kill ${_PS_TO_KILL}${unbold}.
"
fi

# done
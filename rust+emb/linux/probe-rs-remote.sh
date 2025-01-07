#!/bin/bash
set -e

# Set up 'probe-rs-remote' as 'probe-rs' command.
#
# The calling script is expected to set up '~/.bashrc' with 'export PROBE_RS_REMOTE=probe-rs@192.168.1.199', based
# on interactive query from the user.
#
# See -> https://github.com/lure23/probe-rs-remote
#
[ -d ~/bin ] || ( echo &>2 "Missing '~/bin'"; false )

curl -fsSL -o ~/bin/probe-rs-remote.sh https://raw.githubusercontent.com/lure23/probe-rs-remote/refs/heads/main/sh/probe-rs-remote.sh
chmod a+x ~/bin/probe-rs-remote.sh

(cd ~/bin && ln -s probe-rs-remote.sh probe-rs)

# Create an ssh key for (later; manual) pairing
#
# Ref -> https://unix.stackexchange.com/questions/69314/automated-ssh-keygen-without-passphrase-how
#
cat /dev/zero | ssh-keygen -t rsa -C "for 'probe-rs' remote" -q -N ""

# The manual step (once 'PROBE_RS_REMOTE' is really known):
#ssh-copy-id $PROBE_RS_REMOTE

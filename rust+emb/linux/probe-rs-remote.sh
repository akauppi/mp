#!/bin/bash
set -e

# Set up 'probe-rs' and 'espflash' to use ssh.
#
# The calling script is expected to set up '~/.bashrc' with 'export PROBE_RS_REMOTE=probe-rs@192.168.1.199', based
# on interactive query from the user.
#
# See -> https://github.com/lure23/probe-rs-remote
#
[ -d ~/bin ] || ( echo &>2 "Missing '~/bin'"; false )

curl -fsSL -o ~/bin/probe-rs-remote.sh https://raw.githubusercontent.com/lure23/probe-rs-remote/refs/heads/main/sh/probe-rs-remote.sh
chmod a+x ~/bin/probe-rs-remote.sh

curl -fsSL -o ~/bin/espflash-remote.sh https://raw.githubusercontent.com/lure23/probe-rs-remote/refs/heads/main/sh/espflash-remote.sh
chmod a+x ~/bin/espflash-remote.sh

(cd ~/bin && \
  ln -s probe-rs-remote.sh probe-rs && \
  ln -s espflash-remote.sh espflash \
)

# Create an ssh key for (later; manual) pairing
#
# Ref -> https://unix.stackexchange.com/questions/69314/automated-ssh-keygen-without-passphrase-how
#
ssh-keygen < /dev/zero > /dev/null \
  -t rsa -C "for 'probe-rs' remote" -q -N ""
  # without '/dev/null' would output: <<
  #   Enter file in which to save the key (/home/ubuntu/.ssh/id_rsa):
  # <<

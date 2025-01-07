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

(cd ~/bin && ln -s probe-rs-remote.sh probe-rs)

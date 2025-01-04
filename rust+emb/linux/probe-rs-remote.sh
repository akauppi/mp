#!/bin/bash
set -e

# Set up 'probe-rs-remote' as 'probe-rs' command.
#
# NOTE #1: YOU MUST EDIT the line in '~/.bashrc' to provide the correct value for 'PROBE_RS_REMOTE' env.var. before use!
#
# Note #2: Upstream changes are not reacted to; ideally, 'probe-rs-remote' could be available as a 'cargo' extension,
#   making its updates easier to gain.
#
# See -> https://github.com/lure23/probe-rs-remote
#

install -d ~/bin
echo 'PATH="$PATH:$HOME/bin"' >> ~/.bashrc

curl -fsSL -o ~/bin/probe-rs-remote.sh https://raw.githubusercontent.com/lure23/probe-rs-remote/refs/heads/main/sh/probe-rs-remote.sh

(cd ~/bin && ln -s probe-rs-remote.sh probe-rs)

echo -e '\n# EDIT AND UNCOMMENT THIS\n#export PROBE_RS_REMOTE=probe-rs@192.168.1.199' \
  >> ~/.bashrc

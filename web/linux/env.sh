#!/bin/bash
set -e

# Note. This didn't work, since '$0' is just "sh"
#_ADD=$(dirname $0)/.bashrc.add
_ADD=~/.mp/.bashrc.add

cat >> ~/.bashrc < ${_ADD}

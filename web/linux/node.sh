#!/bin/bash
set -e

# Node.js setup
#
# We prefer 'nodesource' approach (over default Ubuntu 'nodejs npm' packages), because it provides
#   - one less level of abstraction
#   - may offer more variety of versions
#   - is pretty widely used
#
# References:
#   - nodesource > "DEB Supported [...]"
#     -> https://github.com/nodesource/distributions?tab=readme-ov-file#deb-supported-versions

# dependencies
#
(which curl >/dev/null) || \
  (sudo -- sh -c "DEBIAN_FRONTEND=noninteractive apt-get install -y curl")

# Last stable (even) version
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -

sudo -- sh -c "DEBIAN_FRONTEND=noninteractive apt-get install -y nodejs"

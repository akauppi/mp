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
#   - "Install 'npm' packages globally without sudo [...]"
#     -> https://github.com/sindresorhus/guides/blob/main/npm-global-without-sudo.md

#-- sudo
(which curl >/dev/null) || \
  (sudo -- sh -c "apt-get install -y curl")

# Last stable (even) version
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -

sudo -- sh -c "apt-get install -y nodejs"

#-- user
#
install -d "${HOME}/.npm-packages"
  # Note: During debugging, we might already have this folder. Thus, more robust to use 'install -d'.

npm config set prefix "${HOME}/.npm-packages"

cat >> ~/.bashrc << 'EOF'

# 'npm install -g' without needing 'sudo'
#
NPM_PACKAGES="${HOME}/.npm-packages"
export PATH="$PATH:$NPM_PACKAGES/bin"

export MANPATH="${MANPATH-$(manpath)}:$NPM_PACKAGES/share/man"

EOF
  # Linux note: 'EOF': ticks make the contents be passed literally

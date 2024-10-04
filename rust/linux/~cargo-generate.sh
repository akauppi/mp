#!/bin/bash
set -e

# Set up 'cargo generate'

#--- Root ---

sudo -- sh -c "DEBIAN_FRONTEND=noninteractive apt-get install -y \
  libssl-dev \
  "

#--- Normal user ('ubuntu') ---

if [ true ]; then
  time cargo install cargo-generate
    # 233 packages; takes time
else
  # Undone. If we wish to speed things up (?), install 'cargo binstall' from the Linux '.tgz' (it's a binary file)
  # https://github.com/cargo-bins/cargo-binstall?tab=readme-ov-file#manually
  #
  exit 9

  time cargo binstall cargo-generate
fi

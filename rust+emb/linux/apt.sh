#!/bin/bash
set -e

# Install system-level dependencies that may be needed by some 'cargo' add-ons.
#
# Note: These are NOT needed by things that we pre-install, but by something the user might want to install
#   themselves. Just smoothens the wrinkles to have the necessary OS level pre-installed.
#
sudo DEBIAN_FRONTEND=noninteractive \
  apt install -y pkg-config libssl-dev
  #
  # Needed for: "cargo install cargo-generate"

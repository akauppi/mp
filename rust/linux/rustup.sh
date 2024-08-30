#!/bin/bash
set -e

# Preparations for a Rust setup.
#
# Based on:
#   - https://github.com/esp-rs/esp-idf-template/blob/master/cargo/.devcontainer/Dockerfile

#--- Root ---

# dependencies
sudo -- sh -c "DEBIAN_FRONTEND=noninteractive apt-get install -y \
  gcc xz-utils \
  wget flex bison gperf python3 python3-pip python3-venv cmake ninja-build ccache libffi-dev dfu-util \
  "
  # Modified:
  #   - "apt-get update" already done
  #   - caches left; we want other scripts to have updated modules, e.g. 'linux-modules-extra-*'.

#--- Normal user ('ubuntu') ---

# Install rustup
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- \
  --default-toolchain none -y --profile minimal

# '. ~/.cargo/env' appended to '.bashrc'

# Primes 'rustup' so that e.g. 'cargo' can be run, and/or 'rustfmt' installed.
. ~/.cargo/env && rustup default stable

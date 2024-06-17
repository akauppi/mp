#!/bin/bash
set -e

# Extra tooling for 'esp-rs/esp-hal'
#
# See:
#   - Contributing
#     -> https://github.com/esp-rs/esp-hal/blob/main/CONTRIBUTING.md
#
# Note:
#

# 'cargo xtask fmt-workspace' needs 'nightly', and some components added under nightly.
#
rustup update nightly
rustup default nightly
rustup component add rustfmt
rustup component add clippy

# default to 'stable' in normal work
rustup default stable

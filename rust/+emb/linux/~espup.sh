#!/bin/bash
set -e

# Enable Xtensa toolchain. This needs a bit more than RISC-V targeting. It:
#   - installs nightly
#   - takes (way) longer to build
#   - uses ~1.5GB extra VM disk (from 4.6G -> 6.1G)
#
#     KEEP THIS AS OPTIONAL!
#
# Note:
#   Since the whole Xtensa support is installed via 'espup', decided to use that for the name of the file. If other
#   Xtensa-specific things are needed, this is where they belong.
#
# Reference:
#   - Rust on ESP Book > RISC-V anx Xtensa Targets
#     -> https://docs.esp-rs.org/book/installation/riscv-and-xtensa.html

cargo install espup
espup install

echo ". ~/export-esp.sh" >> ~/.bashrc

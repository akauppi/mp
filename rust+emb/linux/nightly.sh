#!/bin/bash
set -e

# Embassy some parts want `nightly`. GOING to work to get this away, but for now:
#
rustup toolchain install nightly

rustup component add rust-src --toolchain nightly-x86_64-unknown-linux-gnu

# ..and for Rust code generation ('bindgen', I think..):
#
rustup component add --toolchain nightly-x86_64-unknown-linux-gnu rustfmt

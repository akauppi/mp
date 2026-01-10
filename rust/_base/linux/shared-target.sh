#!/bin/bash
set -e

# Place 'target' folder for Rust _within the VM file system_!  This increases build times by _13x_!
#
# Rust (1.80.0) is fine having _all the project share_ the same target path, with some gotchas [1][2]. In short:
#   - output binary names should be unique
#   - dependencies built with different features (in different projects) may require one to do a 'cargo clean'?
#
#   This seems acceptable.
#
# The nice part about creating '~/.cargo/config.toml' for this is that it doesn't involve any settings in one's
# Rust projects.
#
#   [1]: "Is it okay to use a single shared directory as Cargo's target directory for all projects?"
#       -> https://stackoverflow.com/questions/58669482/is-it-okay-to-use-a-single-shared-directory-as-cargos-target-directory-for-all
#
#   [2]: "Setting a base target directory"
#       -> https://internals.rust-lang.org/t/setting-a-base-target-directory/12713/9
#

# Just use a blunt name
mkdir ~/target

# The file DOES NOT exist before us. (If it does, and has '[build]' section, need to inject in a TOML-aware way!)
CONFIG_TOML=~/.cargo/config.toml
if [ -f "$CONFIG_TOML" ]; then
    echo >&2 "${CONFIG_TOML} already exists"; false
fi

cat >> $CONFIG_TOML <<EOF
[build]
target-dir = "/home/ubuntu/target"
EOF

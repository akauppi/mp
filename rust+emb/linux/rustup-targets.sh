#!/bin/bash
set -e

# Rust tooling for targeting ESP32 (no-std)
#
# Reference:
#   - Rust on ESP Book > RISC-V Targets Only
#     -> https://docs.esp-rs.org/book/installation/riscv.html

# Rust compilation targets
rustup target add riscv32imc-unknown-none-elf
  # ESP32-{C2|C3}
rustup target add riscv32imac-unknown-none-elf
  # ESP32-{C6|H2}

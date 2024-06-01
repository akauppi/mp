#!/bin/bash
set -e

# Rust targets:
#
# Reference:
#   - Rust on ESP Book > RISC-V Targets Only
#     -> https://docs.esp-rs.org/book/installation/riscv.html

# no-std:
rustup target add riscv32imc-unknown-none-elf
  # For ESP32-C2 and ESP32-C3
rustup target add riscv32imac-unknown-none-elf
  # For ESP32-C6 and ESP32-H2

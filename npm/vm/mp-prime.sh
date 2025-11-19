#!/bin/bash
set -e

# mp-prime.sh
#
# VM script for managing mounts.
#
# Optimize performance of an 'npm' project by mounting its temporary folders, as instructed in '/etc/fstab'.
# We check that:
#   - the folder isn't already mounted
#
# The author knows of no other other mechanism (than shell scripts) to prevent making multiple mounts. While such mounts
# likely do no harm, it just Feels Wrong.
#
# This script can be called from '~/.bashrc'. Without such a script, one would get new mounts per each shell!
#
# '--list' (alone) lists mounts in the _current folder_.
#
usage() {
  echo >&2 "Usage:
  $ $0 [--list] [path-to-mount [, more-paths...]]
"
}

if [[ -z "$1" || "$@" == "--help" ]]; then
  usage
  false
fi

if [[ "$@" == "--list" ]]; then
  mount | grep $(pwd)/
  exit 0
fi

while test $# -gt 0
do
  [[ -d "$1" ]] || (echo >&2 "ERROR: Missing \"$1\""; false)

  if ! mountpoint -q "$1"; then
    mount "$1"

    # extra check (assert-like)
    (mountpoint -q "$1") || (echo >&2 "SEVERE ERROR: Failed to mount \"$1\" (though 'mount' said it succeeded)!"; false)
  else
    echo "$1 already mount-optimized."
  fi

  shift
done

#!/bin/bash
set -e

# VM script
#
# Optimize performance of an 'npm' project by mounting its {build-or-cache} folders, as instructed in '/etc/fstab'.
# The caller calls us for each such folder, and we:
#
#   - ignore the request, if it's already mounted
#   - otherwise, mount it
#
# Mount details come from '/etc/fstab', as stated. There is no other mechanism (than shell scripts) to prevent
# (accidentally) making multiple mounts.
#
# This matters eg. if one places the mount commands in '~/.bashrc'. Without such a script, one would get new mounts
# per each shell!
#
usage() {
  echo >&2 "Usage:
  $ $0 {path-to-mount-point} [{...more...}, ...]
"
}

if [[ -z "$1" ]]; then
  usage
  false
fi

while test $# -gt 0
do
  [[ -d "$1" ]] || (echo >&2 "ERROR: Missing \"$1\""; false)

  if ! mountpoint -q "$1"; then
    mount "$1"
    #(mountpoint -q "$1") || (echo >&2 "ERROR: Failed to mount \"$1\". you should look into this!!"; false)
  else
    echo "$1 already mount-optimized."
  fi

  shift
done

#!/bin/bash
set -e
#set -x  # DEBUG (keep; disabled)

# Optimize use of 'node_modules' and '.svelte-kit' folders, for an npm & SvelteKit project. SEE 'README.md'.
#
# Requires:
#   - jq
#
# Usage:
#   - Run the script within the VM, in an 'npm' project folder
#   - Follow its instructions
#

# Pick up the project id
#
ID=$( ([ -f package.json ] && cat package.json) | jq -r .name) #abc
if [ -z "$ID" ]; then
  echo >&2 "Please run in an npm project - needs 'package.json' with 'name' field."
  false
fi

NODE_MODULES_STORE="$HOME/.node_modules.$ID"

# Make sure folders we need do exist; allows running before 'npm build' or similar.
install -d $NODE_MODULES_STORE node_modules \
  .svelte-kit

cat <<EOF

  To improve 'npm' performance, run the following:

  sudo mount --bind $NODE_MODULES_STORE node_modules

  sudo mount -t tmpfs -o size=5m,uid=1000 \$(openssl rand -hex 12) .svelte-kit

  sudo cat /etc/mtab | grep \$(pwd)/
  <<
  /dev/sda1 /home/ubuntu/FinalYards_website/node_modules ext4 rw,relatime,discard,errors=remount-ro,commit=30 0 0
  d1faf8d85b09aa0edf11349f /home/ubuntu/FinalYards_website/.svelte-kit tmpfs rw,relatime,size=5120k,uid=1000,inode64 0 0
  <<

  Now, append those lines to `/etc/fstab`:

  sudo nano /etc/mtab

  Restart the VM. See that the mounts remain:

  sudo cat /etc/mtab | grep \$(pwd)/

  You should see two lines (same as for the command before the restart).
EOF

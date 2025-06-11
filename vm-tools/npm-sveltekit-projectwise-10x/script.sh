#!/bin/bash
set -e
#set -x  # DEBUG (keep; disabled)

# Optimize use of 'node_modules' and '.svelte-kit' folders, for an npm & SvelteKit project. SEE 'README.md'.
#
# Requires:
#   - openssl
#
# Usage:
#   - Run the script within the VM, in an 'npm' project folder
#   - Follow its instructions
#

# Check we are in an 'npm' folder
[ -f package.json ] || (
  echo >&2 "No 'package.json' found. Please run in an npm project folder."
  false
)

# Pick a random string and map to there
NODE_MODULES_ROOT=$HOME/.node_modules
NODE_MODULES_BIND="$NODE_MODULES_ROOT/$(openssl rand -hex 12)"

# Make sure folders we need do exist; allows running before 'npm build' or similar.
install -d $NODE_MODULES_ROOT node_modules \
  .svelte-kit

cat <<EOF

  To improve 'npm' performance, run the following:

  install -d $NODE_MODULES_BIND
  sudo mount --bind $NODE_MODULES_BIND node_modules

  If you use SvelteKit, also run:

  sudo mount -t tmpfs -o size=5m,uid=1000 \$(openssl rand -hex 12) .svelte-kit

  sudo cat /etc/mtab | grep \$(pwd)/
  <<
  /dev/sda1 /home/ubuntu/FinalYards_website/node_modules ext4 rw,relatime,discard,errors=remount-ro,commit=30 0 0
  d1faf8d85b09aa0edf11349f /home/ubuntu/FinalYards_website/.svelte-kit tmpfs rw,relatime,size=5120k,uid=1000,inode64 0 0
  <<

  Now, append those lines to '/etc/fstab':

  sudo nano /etc/fstab

  Restart the VM. See that the mounts remain:

  sudo cat /etc/mtab | grep \$(pwd)/

  You should see two lines (same as for the command before the restart).
EOF

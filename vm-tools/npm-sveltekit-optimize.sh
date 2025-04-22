#!/bin/bash
set -e
#set -x  # DEBUG (keep; disabled)

# Optimize use of 'node_modules' and '.svelte-kit' folders, for an npm & SvelteKit project.
#
# The problem being solved:
#   Multipass mounts to the host system (on macOS, at least) are *very inefficient* with huge numbers
#   of small files (such as 'node_modules', or Rust/Cargo's 'target'). Such folders also don't need to
#   be shared between the host and the VM. By keeping them local (to the VM) we avoid a substantial (10x)
#   slow-down, compared to native use cases.
#
#   _Unlike_ Rust/Cargo's 'target', 'npm' does not allow the project's 'node_modules' folder to be
#   located elsewhere (via e.g. an env.var). Also, the Multipass 'mount' feature does not provide
#   exceptions to subfolders within a mount.
#
# The solutions:
#   For 'node_modules', local 'mount --bind' seems to override the Multipass mount, allowing us to
#   point the folder to a local partition. Cool!
#
#   For '.svelte-kit', we opt for making a memory-based volume, mounted in the subfolder.
#
#   Note: These both could use either solution. If you want persistence over VM restarts, go with the
#       'mount --bind'.
#
# Downsides:
#   - this script needs to be manually run (once) for each npm/SvelteKit project
#   -
#
# Positive side effects:
#   - the host (an IDE?) and the VM now have fully separate 'npm' caches, which is beneficial if there are
#     binary modules included.
#
# Requires:
#   - jq
#
# Usage:
#   - Map or copy the script to the VM.
#   - <<
#       $ {...}/npm-sveltekit-optimize.sh   # run with the project folder (with 'package.json') as cwd
#       # prepare to provide the 'sudo' pw
#     <<
#

# Pick up the project id
ID=$(cat package.json | jq -r .name) #abc
if [ -z "$ID" ]; then
  echo &>2 "Please run in an npm project - needs 'package.json' with 'name' field."
  false
fi

_CWD=$(pwd)
  # as user, not sudo
  # tbd. disallow running as a root

NODE_MODULES_STORE="$HOME/.node_modules.$ID"
  # with the 'ubuntu' user (not 'root')

SVELTE_KIT_TAG="$ID-svelte-kit"

# Once the mounts are done:
#
#   <<
#   $ mount
#   [...]
#   /dev/sda1 on /home/ubuntu/{...}/node_modules type ext4 (rw,relatime,discard,errors=remount-ro,commit=30)
#   abc-svelte-kit on /home/ubuntu/{...}/.svelte-kit type tmpfs (rw,relatime,size=5120k,uid=1000,inode64)
#   <<
#
if (mount | grep -E "$NODE_MODULES_STORE|$SVELTE_KIT_TAG"); then    # let the mounts show (if any)
  echo >&2 ""
  echo >&2 "Mounts are already in place."
  echo >&2 "You can 'sudo umount {...}' them if you want to retry."
  echo >&2 ""
  false
fi

install -d $NODE_MODULES_STORE

echo "Going to ask for 'sudo' pw to mount:"
echo ""
echo "  'node_modules'  --> $NODE_MODULES_STORE (within the VM)"
echo "  '.svelte-kit'   --> {memory disk}"
echo ""
echo "This avoids mapping dependencies to the host (macOS) file system, making development faster (x10)."
echo ""
read -rsp $'Press a key to continue...\n' -n1 KEY
sudo whoami > /dev/null

sudo mount --bind $NODE_MODULES_STORE node_modules

sudo mount -t tmpfs -o size=5m,uid=1000 $SVELTE_KIT_TAG .svelte-kit

echo ""
mount | grep -E "$_CWD" | grep -v "$_CWD "
  # remove mapping of actual cwd
  
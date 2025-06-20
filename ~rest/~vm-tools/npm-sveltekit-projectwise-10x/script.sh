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
NODE_MODULES_BIND="$NODE_MODULES_ROOT/$(openssl rand -hex 4)"

SVELTEKIT_RAND=$(openssl rand -hex 4)

# Make sure folders we need do exist; allows running before 'npm build' or similar.
install -d node_modules \
  .svelte-kit

cat <<EOF

  1. SHADOW 'node_modules' on VM local

    (( Move to your project folder (the one with 'package.json'). ))

    We'll tie a random string to the mount. Let it be "$NODE_MODULES_BIND" (you can use any!).

    1.1 Make sure the mount point exists

      install -d node_modules

    1.2 Create the mount target; this is within the local VM partition, so will have "native" speed:

      install -d $NODE_MODULES_BIND

    1.3 Add an entry to the '/etc/fstab'. This does two things:
      - allows a mere (owning) user to 'mount' the 'node_modules'
      - allows us to recreate the mount after VM restarts

      <<
        /home/ubuntu/.node_modules/0f9399e3 /home/ubuntu/FinalYards_website/node_modules none user,noauto,bind,rw,relatime,discard,commit=30 0 0
      <<

      sudo nano /etc/fstab

      Try it:

      sudo systemctl daemon-reload
      mount node_modules

      mount | grep \$(pwd)/

      You should be seeing an entry about the 'node_modules' folder.

    1.4 To re-mount after VM restarts

      - either manually do the 'mount node_modules', each time, or add it to your '~/.bashrc' (with full path, of course):

      <<
        mount $HOME/{your-folder}/node_modules
      <<

  2. If you use SvelteKit, make a 'tmpfs' mount (empty after each VM restart):

    1.1 Make sure the mount point exists

      install -d .svelte-kit

    2.2 Add an entry to '/etc/fstab':

      <<
        ba2dd5e6 /home/ubuntu/FinalYards_website/.svelte-kit tmpfs user,noauto,rw,nosuid,nodev,noexec,relatime,size=5120k,uid=1000,gid=1000,inode64 0 0
      <<

      sudo nano /etc/fstab

      Try it:

      sudo systemctl daemon-reload
      mount .svelte-kit

      mount | grep \$(pwd)/

      You should see the 'tmpfs' entry.

    2.3 To re-mount after VM restarts

      - either manually do the 'mount .svelte-kit', each time, or add it to your '~/.bashrc' (with full path, of course):

      <<
        mount $HOME/{your-folder}/.svelte-kit
      <<

    That's it!

    3. Testing

      3.-

      Clear the contents of persistent mounts:

      rm -rf node_modules/* node_modules/.bin

      3.0 Restart your VM, to also test the persistence of the mounts.

      3.1 You should see two entries with:

      # within your 'npm' project folder
      $ mount | grep $(pwd)/
      /dev/sda1 on /home/ubuntu/FinalYards_website/node_modules type ext4 (rw,nosuid,nodev,noexec,relatime,discard,errors=remount-ro,commit=30)
      ba2dd5e6 on /home/ubuntu/FinalYards_website/.svelte-kit type tmpfs (rw,nosuid,nodev,noexec,relatime,size=5120k,uid=1000,gid=1000,inode64,user=ubuntu)

      3.2 'npm install' and 'npm dev' should have native speed

      rm -rf node_modules/*
      rm -rf .svelte-kit/*

      time npm install
      [...]


EOF

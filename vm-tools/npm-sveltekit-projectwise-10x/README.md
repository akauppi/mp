# `npm-sveltekit-projectwise-10x/`

Multipass with `npm` development has some performance issues (at least on macOS). 

This document discusses these performance issues and offers a solution for gaining near-native speed for your build loops. You **do need to apply the fix on a project-by-project basis** - otherwise we'd have taken care of this in the VM setup, itself.


## The problem

Multipass mounts to the host system (on macOS, at least) are *very inefficient* with huge numbers of small files (such as `node_modules`, or Rust/Cargo's `target`). Such folders also don't need to be shared between the host and the VM. By keeping them local (to the VM) we avoid a substantial (10x) slow-down, compared to native use cases.

Unlike Rust/Cargo's `target`, `npm` does not allow the project's `node_modules` folder to be located elsewhere (via e.g. an env.var). Also, the Multipass `mount` feature does not provide exceptions to subfolders within a mount.

## The solutions

For `node_modules`, local `mount --bind` seems to override the Multipass mount, allowing us to point the folder to a local partition. Cool!

For `.svelte-kit` (SvelteKit specific; other frameworks may have similar cache folders), we opt for a memory-based volume, mounted in the subfolder.

>Note: These both could use either solution. If you want persistence over VM restarts also for `.svelte-kit`, go with the `mount --bind`.

## Positive side effects

- the host (an IDE?) and the VM now have fully separate `npm` caches, which is beneficial if there are binary modules included.

## Steps

### Map the `vm-tools` 

Map the `vm-tools` folder to your VM, so you can run scripts from there.

```
$ multipass stop web-cf
 
$ multipass mount --type native ~/vm-tools web-cf:

$ multipass shell web-cf	# to get back...
```

### Within your `npm` project, run the script

```
$ ~/vm-tools/npm-sveltekit-projectwise-10x/script.sh

```

The script instructs you about commands to run (manually). See [here](https://askubuntu.com/a/763645/338886) for the source of them.


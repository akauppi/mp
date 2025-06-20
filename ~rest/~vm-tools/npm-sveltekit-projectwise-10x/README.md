# `npm-sveltekit-projectwise-10x`


Multipass with `npm` development has some performance issues (at least on macOS 15).

This document discusses these performance issues and offers a solution for gaining near-native speed for your build loops. You **do need to apply the fix on a project-by-project basis** - otherwise we'd have taken care of this in the VM setup, itself.

<!--
macOS 15.5
Multipass 1.15.1
-->

## The problem

Multipass mounts to the host system (on macOS, at least) are *very inefficient* with huge numbers of small files (such as `node_modules`, or Rust/Cargo's `target`). Such folders also don't need to be shared between the host and the VM. By keeping them local (to the VM) we avoid a substantial (10x) slow-down, compared to native use cases.

Unlike Rust/Cargo's `target`, `npm` does not allow the project's `node_modules` folder to be located elsewhere (via e.g. an env.var). Also, the Multipass `mount` feature does not provide exceptions to subfolders within a mount.

### Evidence

Running a clean slate `npm install` on a trivial project:

1. No fix (`node_modules` on host)

	```
	$ time ni

	added 325 packages, and audited 326 packages in 2m

	[...]
	real	2m0.154s
	user	0m28.012s
	sys	0m49.081s
	```

2. Fix (`node_modules` bind-mounted to a local VM folder)

	```
	$ time ni

	added 326 packages, and audited 327 packages in 47s

	real	0m47.478s
	user	0m21.928s
	sys	0m19.527s
	```

Only 2.5 x improvement, but I've seen worse.


## The solutions

For `node_modules`, local `mount --bind` seems to override the Multipass mount, allowing us to point the folder to a local partition.

For `.svelte-kit` (SvelteKit specific; other frameworks may have similar cache folders), we opt for a memory-based volume, mounted in the subfolder.

>Note: These mounts need to be applied *after* the initial boot. Multipass does its mount after the Linux system-level mounts (i.e. `/etc/fstab` automatic entries).

These both could use either solution. If you want persistence over VM restarts also for `.svelte-kit`, go with the `mount --bind`. If you don't mind fully re-creating each `node_modules` after a VM restart, you can do `tmpfs` for both. Below, we show both ways.

## Steps

### Map the `vm-tools` 

Map the `vm-tools` folder to your VM, so you can run scripts from there.

```
$ multipass stop web-cf
 
$ multipass mount --type native {path-to}/vm-tools web-cf:

$ multipass shell web-cf	# to get back...
```

### Run the script

Within your `npm` project, run this. It will only show you the commands to manually perform, to set the mounts up:

```
$ ~/vm-tools/npm-sveltekit-projectwise-10x/script.sh

```

See [here]() for the source of them.


## Positive side effects

- the host (an IDE?) and the VM now have fully separate `npm` caches, which is beneficial if there are binary modules included.

## References

- AskUbuntu > `How to make mount --bind permanent?` > [this answer](https://askubuntu.com/a/763645/338886) (Apr 2016)
- Unix & Linux > [What is a bind mount?](https://unix.stackexchange.com/a/198591/83707) (Apr 2015)

###AI searches

- Google > `"linx bind mount persist over reboot"` > AI Overview helped in making the `bind` mount persistent


# mp

Scripts for setting up [Multipass](https://multipass.run) virtual machines, in the way of WSL, but on macOS.

## Background

**Why?**

World is a risky place. Sandboxing allows you to separate *business account* (emails etc.) from *developer account* (that pulls in stuff from third party sources on the Internet), without disturbing the workflow, too much.

One can use containers for development, but Docker Desktop feels too big a tool for daily use, for this author.

**Discipline**

Sandboxing of course needs discipline. The `mp` approach is done so that:

1. Tooling is separate from development repos

   This is important so that your repos are not cluttered by toolchain choices. A repo would work "just fine" with native tooling (on Ubuntu Linux), if someone so wishes.

2. We want to support remote IDE's (later..)

   This requires a beefier machine (more cores; more memory). You might opt for partially VM-based workflows, but it's still better than not starting the sandbox transition.

**Alternatives**

Fully cloud-based sandbox-as-a-service comes to mind. 

- [Jetbrains Space](https://www.jetbrains.com/space/)
- ..other vendors have similar

This can be ideal for you, but this author prefers to have the *option* of locally hosted, offline-capable development.

It's possible, by -say- 2026, that such remote development platforms become the norm. They certainly have many things going for them, in the same way as multiplayer games have.


## Sandboxes available

- [`rust`](rust/README.md); stable
- [`rust+emb`](rust+emb/README.md); stable

	Rust aimed at embedded (ESP32) development.

- [`web`](web/README.md); stable
- [`web+cf`](web+cf/README.md)

	Cloudflare CLI (`wrangler`) on top of generic web tools.

## Requirements

- Multipass 1.14.0 installed

The system is intended to work on all macOS, Linux and Windows hosts, but is only tested on macOS. If you find issues, please create an Issue!

>Note: For Windows, Pro versions are recommended since only they provide Hyper-V (native) virtualization.

<!-- Developed with:
- macOS 14.7
- Multipass 1.14.1-RC1
-->

## Usage

```
$ rust/prep.sh
[...]
```

>It works the same for `web/prep.sh`.

```
Multipass IP (rust): 192.168.64.74

cargo 1.80.1 (376290515 2024-07-16)
rustc 1.80.1 (3f5fd8dd4 2024-08-06)
usbip (usbip-utils 2.0)

```

To add a project folder to be shared between the host (macOS) and the Linux side:

```
$ multipass stop rust-emb
$ multipass mount --type native $(pwd) rust-emb:/home/ubuntu/SOME
$ multipass start rust-emb
```

Then:

```
$ multipass shell rust-emb
```

You are now in an Ubuntu sandbox.

## Hints

### Separate color for the VM terminal

Change your Multipass terminal's look by `(right click)` > `Show Inspector`. Different coloring helps tremendously!

### Accessing USB devices

Multipass does not provide USB pass-through. However, you can reach USB devices using e.g. [`usbipd-win`](https://github.com/dorssel/usbipd-win).

*tbd. If needed, a separate `docs/` file about this.*


## 📛WARNING ON MULTIPASS 1.14.0!!

It has issues with mounts, and/or active instances in general. Until those are resolved, you should:

- **AVOID** any maintenance-like commands on a **running instance**

   This means no `multipass mount`, `umount`, `restart` or `delete`.
   
   Instead, do a `multipass stop` first, and then the required maintenance command (turning `restart` into a `stop` + `start`).
   
   This seems to immensely (perhaps completely!) improve the stability of the Multipass VM.
   
- IF you end up in suspicious errors, instantly:

	- restart your host
	- `stop` and `delete --purge` all instances
	- check that `multipass info` gives "no instances"
	- ...continue

A bit harsh, but.. since you can easily recreate the VM's from nothing (with `mp`), shouldn't be worth risking the stability. 

## Troubleshooting

IF you get such an error:

```
$ mp stop --force rust-emb
[2024-08-30T12:30:41.371] [error] [rust-emb] process error occurred Crashed program: qemu-system-x86_64; error: Process crashed
[2024-08-30T12:30:41.373] [error] [rust-emb] error: program: qemu-system-x86_64; error: Process crashed
```

...restart the Multipass service, and retry the `stop` (no host reboot is needed):

```
$ sudo launchctl unload /Library/LaunchDaemons/com.canonical.multipassd.plist
$ sudo launchctl load /Library/LaunchDaemons/com.canonical.multipassd.plist
```

```
$ mp stop rust-emb
```

---

If you get:

```
start failed: cannot connect to the multipass socket
```

Same thing. Don't try to be brave. Just restart the computer!


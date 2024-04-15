# mp

Scripts for setting up [Multipass](https://multipass.run) virtual machines, in the way of WSL, but on macOS.

**Why?**

World is a risky place. Sandboxing allows you to separate *business account* (emails etc.) from *developer account* (that pulls in stuff from third party sources on the Internet), without disturbing the workflow, too much.

One can use containers for development, but Docker Desktop feels too big a tool for daily use, for this author.

**Discipline**

Sandboxing of course needs discipline. The `mp` approach is done so that:

1. Tooling is separate from development repos

   This is important so that your repos are not cluttered by toolchain choices. A repo would work "just fine" with native tooling, if someone so wishes.

2. We want to support remote IDE's

   However, this does require a beefier machine to run (more cores; more memory). You might opt for partially VM-based workflows, but it's still better than not starting the sandbox transition.

**Alternatives**

Fully cloud-based sandbox-as-a-service comes to mind. 

- [Jetbrains Space](https://www.jetbrains.com/space/)
- ..other vendors have similar

This can be ideal for you, but this author prefers to have the *option* of locally hosted, offline-capable development.

It's possible, by -say- 2026, that such remote development platforms become the norm. They certainly have many things going for them, in the same way as multiplayer games have.


## Sandboxes available

- [`rust`](rust/README.md); stable
- [`web`](web/README.md); WIP

## Usage

```
$ rust/prep.sh
[...]
```

>It works the same for `web/prep.sh`.

```
Multipass IP (rust): 192.168.64.74

cargo 1.75.0 (1d8b05cdd 2023-11-20)
rustc 1.75.0 (82e1608df 2023-12-21)
usbip (usbip-utils 2.0)

```

To add a project folder to be shared between the host (macOS) and the Linux side:

```
$ multipass mount -type native $(pwd) rust:/home/ubuntu/SOME

$ multipass start rust
```

Then:

```
$ multipass shell rust
```

You are now in an Ubuntu sandbox.

<!--
>Hint: Change your Multipass terminal's look by (right click) > `Show Inspector`.
-->

### Sharing USB devices

To see how to share a USB device, see e.g. [`usbipd-win`]().

```
rust$ sudo usbip attach -r 192.168.1.29 -b 3-1
```
```
rust$ lsusb
Bus 002 Device 001: ID 1d6b:0003 Linux Foundation 3.0 root hub
Bus 001 Device 002: ID 1a86:55d4 QinHeng Electronics SONOFF Zigbee 3.0 USB Dongle Plus V2
Bus 001 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
```

>Note: Sharing like this, you'll always get a predictable device name in the Multipass VM. In this case, "Device 002" shows as `/dev/ttyACM0`.

### Updating

```
rust$ rustup update
...
```

### Troubleshooting

**Kernel version has upgraded**

```
libusbip: error: udev_device_new_from_subsystem_sysname failed
usbip: error: open vhci_driver
```

If you get this info, like `sudo apt upgrade` has increased your Linux kernel, and the `vhci-hcd` driver isn't available, any more.

>```
>$ sudo ls /lib/modules
>5.15.0-92-generic  5.15.0-94-generic
>```
>
>Likely set up as `5.15.0-92`. Updated to `..-94`.

Rerun commands from `rust/linux/usbip-drivers.sh`:

```
$ sudo apt install -y linux-tools-generic linux-modules-extra-$(uname -r)
[...]
$ sudo modprobe vhci-hcd
```

The `usbip attach -r {IP} -b ...` should no work.

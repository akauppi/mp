# mp-sandbox

Scripts for setting up [Multipass](https://multipass.run) virtual machines, in the way of WSL, but on macOS.

**Why?**

One can use containers (like Docker) for development, but Docker Desktop may feel too big a tool for daily use.

Because of security. Sandboxing allows you to separate *business account* (emails etc.) from *developer account* (that pulls in stuff from N sources on the Internet), without disturbing the workflow, too much.

**Discipline**

Sandboxing of course needs discipline. The `mp` approach is done so that:

- tooling is separate from development repos

   This is important so that your repos are not cluttered by toolchain choices. A repo would work "just fine" with native tooling, if someone so wishes.

## Sandboxes available

- [`rust`](#Rust)

## Usage

```
$ rust/prep.sh
[...]

Multipass IP (rust): 192.168.64.74

cargo 1.75.0 (1d8b05cdd 2023-11-20)
rustc 1.75.0 (82e1608df 2023-12-21)
usbip (usbip-utils 2.0)

```

After that:

```
$ multipass shell rust
```

You are now in an Ubuntu sandbox.

Map a working directory to the sandbox.

```
$ multipass mount $(pwd) rust:/home/ubuntu/Git/Something
```

After this, you'll see the same files on both the host (macOS) and Linux side.

<!--
>Hint: Change your Multipass terminal's look by (right click) > `Show Inspector`.
-->

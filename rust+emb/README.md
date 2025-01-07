# Rust for embedded development

Intended for [Embassy](https://embassy.dev) development, this VM sets up:

- Rust compilation targets (ESP32-C3, ESP32-C6)
- [probe-rs-remote](https://github.com/lure23/probe-rs-remote) connection to a computer with [`probe-rs`](https://probe.rs) installed

<!-- tbd.
- `nightly` toolchain, as long as it's needed/favoured by Embassy
-->


## Overall

![](.images/probe-rs-setup.png)


You'll be connecting the development kit (e.g. [ESP32-C6-DevKitC](https://docs.espressif.com/projects/esp-dev-kits/en/latest/esp32c6/esp32-c6-devkitc-1/user_guide.html#esp32-c6-devkitc-1-v1-2)) to *another* computer; either a Raspberry Pi or a Linux PC, which needs to have `probe-rs` installed.

This gives the benefit that your development board is *airgapped* from the development system, where you run your IDE etc. If something were to go wrong with electronics (read: SMOKE!), you'll appreciate this!

><small>As a side note, with Multipass we'd need some way of passing USB over IP anyhow, since Multipass does not support USB device mapping.</small>


## Preparations

If you already have the assisting computer (Raspberry Pi) set up, great! Feed its `ssh` user and IP to the creating script, below.

If you don't, you can either:

- visit [`probe-rs-remote`](https://github.com/lure23/probe-rs-remote) 
- ..or let the default (`probe-rs@192.168.1.199`) be used for now and edit it later in VM's `~/.bashrc`.


## Usage

Create the VM by:

```
$ [PROBE_RS_REMOTE={user@ip}] rust+emb/prep.sh
...
VM is ready.

```

<!-- #hidden
### Xtensa based chips

To enable Xtensa targets, add `XTENSA=1` before the command. Be aware that this consumes ~1.5GiB more disk space from the image.
-->


## Mounting work folders

The idea is that your software would remain on the host disk, shared with the Multipass VM (where the development tools sans IDE reside).

Say you have a folder `/Users/mike/Git/some-project`. This is how to share it with the VM, as `~/some-project`.

>Note: We use "native" folder sharing, which is said to be faster than the default. It does, however, need the VM to be stopped when mounts are added/removed.

```
[host]$ multipass stop rust-emb
```

```
[host]$ multipass mount --type=native /Users/mike/Git/some-project rust-emb:/home/ubuntu/some-project
```

```
[host]$ multipass shell rust-emb
```


## Maintenance

**Updating (within the sandbox)**

```
$ rustup update
```

### `probe-rs-remote`

`~/bin/probe-rs-remote.sh` script currently needs manual care, if you wish to bring updates to it.


## What's not in the box

Once you have `cargo` and suitable toolchains installed, adding more tools is easy. Here are some examples that particular projects might ask you to add:

- `clang`

	A compiler needed if projects contain C/C++ code. Install by:

	```
	$ sudo apt install llvm-dev libclang-dev clang
	```

- `bindgen` CLI

	Generator for Rust/C interfaces. Install by:
	
	```
	$ cargo install bindgen-cli
	```

## Next

```
$ multipass shell rust-emb
```


<!--
## References

- [`probe-rs` docs](https://probe.rs/docs/)
-->


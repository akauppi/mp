# Rust for embedded development

Intended for [Embassy](https://embassy.dev) development, this VM sets up:

- Rust compilation targets (ESP32-C3, ESP32-C6)
- [probe-rs-remote](https://github.com/lure23/probe-rs-remote): connection to an external computer with `probe-rs` and `espflash` installed


## Overall

![](.images/probe-rs-setup.png)


You'll be connecting the development kit (e.g. [ESP32-C6-DevKitC](https://docs.espressif.com/projects/esp-dev-kits/en/latest/esp32c6/esp32-c6-devkitc-1/user_guide.html#esp32-c6-devkitc-1-v1-2)) to *another* computer; either a Raspberry Pi or a Linux PC, which needs to have `probe-rs` and `espflash` installed.

This gives the benefit that your development board is **galvanically isolated** from the development system, where you run your IDE etc. If something were to go wrong with electronics (read: SMOKE!), you'll appreciate this!

> [!NOTE]
>With Multipass we'd need some way of passing USB over IP anyhow, since Multipass does not support USB device mapping.


## Preparations

If you already have the assisting computer (Raspberry Pi) set up, great! Feed its `ssh` user and IP to the creating script, below.

If you don't, visit [`probe-rs-remote`](https://github.com/lure23/probe-rs-remote) to see how to set things up.

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

Say you have a folder `/Some/path/to/circus`. This is how to share it with the VM, as `~/circus`.

>Note: We use "native" folder sharing, which is said to be faster than the default. It does, however, need the VM to be stopped when mounts are added/removed.

```
[host]$ multipass stop rust-emb
```

```
[host]$ multipass mount --type=native /Some/path/to/circus rust-emb:
```

```
[host]$ multipass shell rust-emb
```

## Finishing `probe-rs` tunneling

You can already use the VM to build embedded Rust code, but to flash them onto a hardware device, `probe-rs` tunnelling needs to be set up. 

> [!NOTE]
>We don't do this automatically, since that would mean you *must* have the assistant computer available by the time you run `prep.sh`. That might not be the case; or perhaps you just wish to have a build environment.

Enter the VM:

```
$ multipass shell rust-emb
```

What is needed is:

1. Confirm the `PROBE_RS_REMOTE` value

	```
	$ echo $PROBE_RS_REMOTE
	probe-rs@192.168.1.199
	```

	Is this the `ssh` user and IP, to reach your Raspberry Pi? 

	If so, carry on. 

	If not, prepare it by editing `~/.bashrc` (and `. ~/.bashrc` to bring in the changes).

2. Copy over the `ssh` public key

	`prep.sh` has already created a key-pair we can use for the authentication (see it with `ls -al ~/.ssh`). 

	```
	$ ssh-copy-id $PROBE_RS_REMOTE
	/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/home/ubuntu/.ssh/id_ed25519.pub"
	The authenticity of host '192.168.1.199 (192.168.1.199)' can't be established.
	ED25519 key fingerprint is SHA256:d+UMTm6/gW9NtWmBFG8mDXVgkTGmAaN6PVesgHxZQUg.
	This key is not known by any other names.
	Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
	/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
	/usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
	probe-rs@192.168.1.199's password: 

	Number of key(s) added: 1

	Now try logging into the machine, with:   "ssh 'probe-rs@192.168.1.199'"
	and check to make sure that only the key(s) you wanted were added.
	```

	>You enter the `yes` and the password to the assistant computer.

Now, you should be able to:

```
$ probe-rs list
No debug probes were found.
```

Attach the devkit to the Raspberry Pi (use the USB/JTAG port or if you only have USB/UART, run `espflash board-info`).

```
$ probe-rs list
The following debug probes were found:
[0]: ESP JTAG -- 303a:1001:54:32:04:07:15:10 (EspJtag)
```


## Maintenance

### Updating (within the sandbox)

```
$ rustup update
```

### Freeing disk space

The `~/target` folder is used for *all* Cargo compilation caching (steered by `~/.cargo/config.toml`). This folder may grow considerably large and is always safe to remove.

```
$ du -h -d 1 ~/target
1.6G	/home/ubuntu/target/release
247M	/home/ubuntu/target/thumbv7em-none-eabihf
783M	/home/ubuntu/target/debug
753M	/home/ubuntu/target/riscv32imac-unknown-none-elf
3.4G	/home/ubuntu/target
```

```
$ rm -rf ~/target
```

This helps you control the disk space use of the VM instance.

### `probe-rs-remote`

`~/bin/probe-rs-remote.sh` and `~/bin/espflash-remote.sh` scripts currently need manual care, if you wish to bring updates to them. Just copy-paste from the source:

```
$ curl https://raw.githubusercontent.com/lure23/probe-rs-remote/refs/heads/main/sh/probe-rs-remote.sh \
  -o ~/bin/probe-rs-remote.sh

$ curl https://raw.githubusercontent.com/lure23/probe-rs-remote/refs/heads/main/sh/espflash-remote.sh \
  -o ~/bin/espflash-remote.sh
```


## What's not in the box

Once you have `cargo` and suitable toolchains installed, adding more tools is easy. Here are some examples that particular projects might ask you to add:

- `clang`

	A compiler needed if projects contain C/C++ code. Install by:

	```
	$ sudo apt install libclang-dev clang
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


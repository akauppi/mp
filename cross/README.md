# Cross compiling with Rust

This folder is for cross-compiling Rust binaries (such as the `probe-rs` tool) to the [Raspberry Pi 3B](https://www.raspberrypi.com/products/raspberry-pi-3-model-b/) platform. This platform (though having 1GB of RAM) is not sufficient for Rust compiler stack

You can apply this setup for cross-compiling other such tools, of course.

Unlike the other *recipies* in this repo, this one is provided as manual steps. This is because the steps are one-time-only, and the end result is an executable, not a VM.


## Requirements

- Multipass installed and healthy



## Steps

### 1. Create a Docker-containing VM

```
$ multipass launch docker
$ multipass shell docker
```

*Test with:*

>```
>[docker]$ docker --version
Docker version 27.4.1, build b9d17ea
```

### 2. Install tools

Here, we (re)use the `rust/linux/*.sh` scripts.

#### Host side

```
$ multipass stop docker
$ multipass mount --type=native ../rust/linux docker:/home/ubuntu/.mp
```

```
$ multipass exec docker -- sh -c ". ~/.mp/rustup.sh"
$ multipass exec docker -- sh -c ". .cargo/env && . ~/.mp/rustfmt.sh"
```

<!-- #whisper
Running `shared-target.sh` would not provide value, since we're building anyways within VM file system (not mapped to host).
-->

#### VM side

```
$ multipass shell docker
```

>```
>[docker]$ cargo --version
cargo 1.83.0 (5ffbef321 2024-10-29)
>```


### 3. Follow `probe-rs` [steps](https://probe.rs/docs/library/crosscompiling/)

We've rearranged the commands; hopefully everything still works.

#### 3.1 Fetch sources

```
[docker]$ git clone https://github.com/probe-rs/probe-rs
```

```
[docker]$ cd probe-rs
```

#### 3.2 Create a Docker image

```
[docker]$ mkdir crossimage
```

```
[docker]$ cat > crossimage/Dockerfile <<EOF
FROM rustembedded/cross:armv7-unknown-linux-gnueabihf-0.2.1
ENV PKG_CONFIG_ALLOW_CROSS=1
ENV PKG_CONFIG_LIBDIR=/usr/lib/arm-linux-gnueabihf/pkgconfig
RUN dpkg --add-architecture armhf && \
    apt-get update && \
    apt-get install -y libusb-1.0-0-dev:armhf libftdi1-dev:armhf libudev-dev:armhf
EOF
```

```
[docker]$ docker build -t crossimage crossimage/
[+] Building 31.0s (3/5)								docker:default
[...]
 => => naming to docker.io/library/crossimage			0.0s
```

We now have a `crossimage` Docker image built:

>```
>$ docker images
REPOSITORY     TAG       IMAGE ID       CREATED          SIZE
crossimage     latest    87cdd66eebcc   32 minutes ago   1.04GB
>[...]
>```

#### 3.2 Install and use `cross`

<!--
>**SKIP THIS**
>```
>[docker]$ cat >> Cargo.toml <<EOF
>[target.armv7-unknown-linux-gnueabihf]
>image = "crossimage"
>EOF
>```
-->

```
[docker]$ cargo install cross
```

```
[docker]$ cross build -p probe-rs-tools --release --target=armv7-unknown-linux-gnueabihf
```

>```
>[docker]$ file target/armv7-unknown-linux-gnueabihf/release/probe-rs
>target/armv7-unknown-linux-gnueabihf/release/probe-rs: ELF 32-bit LSB pie executable, ARM, EABI5 version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux-armhf.so.3, for GNU/Linux 3.2.0, BuildID[sha1]=3214d84cfb4b080e1e0dd6530341621c70320eb3, not stripped
>```
>
>That looks like a valid `armv7-unknown-linux-gnueabihf` ELF binary.

### 4. Move to the Raspberry Pi

You need to know the IP (and user) of your Raspberry Pi. Then:

```
[docker]$ export RPI=192.168.1.199		# <-- YOURS
[docker]$ scp target/armv7-unknown-linux-gnueabihf/release/probe-rs user@$RPI:/home/user/
user@192.168.1.199's password:
probe-rs                              
```

```
user@rpi:~ $ ./probe-rs --version
probe-rs 0.25.0 (git commit: v0.25.0-5-g9a767f2-modified)
```

Looks good!

### 5. Find a good place for it..

Let's move it to `~/bin` (or any destination you fancy), and add that to the `PATH`:

```
user@rpi:~ $ mkdir bin
user@rpi:~ $ mv probe-rs bin/
```

```
user@rpi:~ $ echo >> ~/.bashrc 'export PATH="$PATH:$HOME/bin"'
```

```
user@rpi:~ $ source ~/.bashrc
```

## Test with a development board

Insert a USB cable to a dev board

```
$ lsusb
[...]
Bus 001 Device 006: ID 303a:1001 Espressif USB JTAG/serial debug unit
[...]
```

```
$ probe-rs list
The following debug probes were found:
[0]: ESP JTAG -- 303a:1001:54:32:04:44:74:C0 (EspJtag)
```

Now, one should be able to do all the normal `probe-rs run` etc. commands, using a Raspberry Pi. The idea is that a main computer would proxy such commands to the RPi, providing *air-gapping* from a development board but also not falling victim to a slow USB/IP flashing.

Such steps are beyond the concerns of this repository, however. We showed how to cross-compile Rust binaries to an architecture where Rust toolchain couldn't (presumably; did not even try!) be set up, using Multipass. That was the goal of this folder.


## References

- [`probe-rs` > Crosscompiling](https://probe.rs/docs/library/crosscompiling/)
- [Docker on Mac – a lightweight option with Multipass](https://ubuntu.com/blog/docker-on-mac-a-lightweight-option-with-multipass) (Aug'23)



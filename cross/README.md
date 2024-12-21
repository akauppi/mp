# Cross compiling with Rust

This folder is for cross-compiling Rust binaries (such as the `probe-rs` tool) to the [Raspberry Pi 3B](https://www.raspberrypi.com/products/raspberry-pi-3-model-b/) platform. This platform (though having 1GB of RAM) is not sufficient for Rust compiler stack. You can also adopt this setup for cross-compiling other such tools, of course.

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
>Docker version 27.4.1, build b9d17ea
>```

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
>cargo 1.83.0 (5ffbef321 2024-10-29)
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
>REPOSITORY     TAG       IMAGE ID       CREATED          SIZE
>crossimage     latest    87cdd66eebcc   32 minutes ago   1.04GB
>[...]
>```

#### 3.2 Install and use `cross`

```
[docker]$ cargo install cross
```

>Note: Unlike the official instructions, adding lines to `Cross.toml` does not seem to be needed.

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

### 5. RPi target setup

We now have the binary on the Raspberry Pi target. Let's move it to a comfortable place and set up the environment (access rights etc.).

#### Comfortable location

Move the binary to `~/bin` (or any destination you fancy), and add that to the `PATH`:

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

#### `udev` configuration

The rest of the steps arise from the tail of [`../rust+emb/linux/probe-rs.sh`](../rust+emb/linux/probe-rs.sh).

The easiest might be to have a temporary script on RPi, such as:

```
#!/bin/sh

_RULES_SOURCE_URL=https://probe.rs/files/69-probe-rs.rules
_RULES_FN=$(basename ${_RULES_SOURCE_URL})
_RULES_TARGET=/etc/udev/rules.d/${_RULES_FN}
_RULES_TMP=/tmp/${_RULES_FN}

curl --proto '=https' --tlsv1.2 -LsSf ${_RULES_SOURCE_URL} -o ${_RULES_TMP}
sudo mv ${_RULES_TMP} ${_RULES_TARGET}

sudo udevadm control --reload

sudo udevadm trigger
```

<!-- #whisper
#sudo usermod -a -G plugdev ${USER}
This didn't seem to be needed (`rust+emb` setup has it).
-->

Then:

```
user@rpi:~ $ ./{temp-name}.sh && echo OK
OK
```


## Test with a development board

Insert a USB cable to a dev board

```
$ probe-rs list
The following debug probes were found:
[0]: ESP JTAG -- 303a:1001:54:32:04:44:74:C0 (EspJtag)
```

Now, one should be able to do all the normal `probe-rs run` etc. commands, using a Raspberry Pi. The idea is that a main computer would proxy such commands to the RPi, providing *air-gapping* from a development board but also not falling victim to a slow USB/IP flashing.

Such steps are beyond the concerns of this repository, however..

## Flashing

Move some compiled file to the RPi, and try:

```
user@rpi:~ $ probe-rs run --log-format '{t:dimmed} [{L:bold}] {s}' a
      Erasing ✔ 100% [####################] 384.00 KiB @ 292.17 KiB/s (took 1s)
  Programming ⠤  94% [###################-] 156.62 KiB @  27.95 KiB/s (ETA 0s)    
```

>Note: Using USB/IP, the flashing speed is often < 2 KiB/s. We've reached a 15x improvement (or down from 2min -> 6s) by running `probe-rs` near the embedded device.

## Integration with your build workflow

This is beyond this folder's aims!

## Clean-up

Once you have placed `probe-rs` on the target, there's likely no need for the `docker` VM to be kept around. You can remove it by:

```
$ multipass stop docker
$ multipass delete --purge docker
```

This releases some 10GB of your disk space.


## References

- [`probe-rs` > Crosscompiling](https://probe.rs/docs/library/crosscompiling/)
- [Docker on Mac – a lightweight option with Multipass](https://ubuntu.com/blog/docker-on-mac-a-lightweight-option-with-multipass) (Aug'23)



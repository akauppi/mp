# Rust development

For Rust development. 
   
Has:

- `rustc`
- `cargo`

<!-- #skip
Flavours: 

- Embedded: generally anything `no_std` where you'd work on MCU's (nRF5x, ESP32 etc.)
- WASM: building for the browser
-->

This README contains the common features. For particular flavours, check out:

- [`+emb`](./+emb/README.md); Rust in embedded
- [`+wasm`](./+wasm/README.md); Rust in the browser


## Build

Launch with one of the flavours, e.g.

```
$ rust/+emb/prep.sh
```


## Maintenance

Updating (within the sandbox):
   
```
$ rustup update
```

Command line completion:

```
$ rustup completions bash       > ~/.local/share/bash-completion/completions/rustup
$ rustup completions bash cargo > ~/.local/share/bash-completion/completions/cargo
```

Cleanup (reclaim disk space):

```
# cd to any Rust project folder (one with `cargo.toml`)
$ cargo clean
```

>Since all projects share the same `~/target` folder, it's enough to do this in any Cargo project folder. It clears for all.

### Cleanup (optional)

Especially important in the embedded toolchain. Dependencies can pile up here:

```
$ du -h -d1 ~/.cargo
 73M	xxx/.cargo/bin
1,1G	xxx/.cargo/registry
2,8G	xxx/.cargo/git
4,0G	xxx/.cargo
```

Running `cargo clean` does not touch these. There are at least two ways to garbage-collect these (and you can always also `rm -rf` the whole folder.

#### a. `cargo cache` extension

Install it separately:

```
$ cargo install cargo-cache
```

Allows you to see the space (well, `du -f -d1` isn't much different):

```
$ cargo cache -a
Clearing cache...

Cargo cache '/home/ubuntu/.cargo':

Total:                                    1.08 GB => 552.58 MB
  38 installed binaries:                             394.54 MB
  Registry:                             687.27 MB => 158.03 MB
    Registry index:                                   28.00 MB
    803 crate archives:                              130.04 MB
    711 => 0 crate source checkouts:         529.24 MB => 0  B
  Git db:                                                 0  B
    0 bare git repos:                                     0  B
    0 git repo checkouts:                                 0  B

Size changed 1.08 GB => 552.58 MB (-529.24 MB, -48.92%)
```

#### b. `cargo +nightly clean gc`

This will hopefully become the automatic solution for keeping `~/.cargo` slim. Until that day, you can run it as:

```
$ cargo +nightly clean gc -Z gc
```

>[! NOTE]
>The command gc's dependencies both for `stable` and `nightly`, though running it is done on the night side.. 🌓

# Rust development

For normal Rust development. 
   
Has:

- `rustc`
- `cargo`

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

## More cleanup (optional)

```
$ du -h -d1 ~/.cargo
 73M	xxx/.cargo/bin
1,1G	xxx/.cargo/registry
2,8G	xxx/.cargo/git
4,0G	xxx/.cargo
```

Running `cargo clean` does not touch these. 

They contain valid caches of crates, including their uncompressed sources, and git repo checkouts you've used as dependencies.

However, since they don't get properly garbage collected <sup>`|1|`</sup>, they may also carry unnecessary old stuff, or duplicates.

<small>
`1`: ["Cargo cache cleaning"](https://blog.rust-lang.org/2023/12/11/cargo-cache-cleaning/) (blog; Dec'23); about the `cargo clean gc`
</small>

You can `rm -rf` any or all of the above folders, but there are more refined solutions coming up:

### a) `cargo cache` extension

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

### b) `cargo +nightly clean gc`

This will hopefully become the automatic solution for keeping `~/.cargo` slim. Until that day, you can run it as:

```
$ cargo +nightly clean gc -Z gc
```

Note that you can use it, even if your projects are using `stable` Rust.

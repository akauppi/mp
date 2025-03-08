# Rust for desktop / WASM development

Adds to the bare Rust + `cargo` setup:

- `build-essentials` (`cc`)

	- needed for building e.g. [`libm`](https://crates.io/crates/libm) crate


## Mounting folders

If you find a need to repeatedly mount same folders, consider creating a `custom.mounts.list` file:

```
#
# Folders to be mounted to a new VM.
#
#   <<
#       $ multipass mount --type=native {path} {MP_NAME}:
#   <<
#
~/Sources/ISOtope
```

Simply list the paths you wish to be mounted on the VM. The example will show as `ISOtope` at the VM home directory.


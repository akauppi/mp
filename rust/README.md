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
$ cargo clean
```

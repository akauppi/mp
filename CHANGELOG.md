# 20-Jun-25

Restructured `web` side, merging `web` and `web+cf` together under `npm` folder.

`wrangler` no longer has its own script; instead, just instructions and (host side) support script. This is simpler, and works just as well.

You can now "add" `wrangler` (or other CLI's) to any `npm` image. This was the main reason for the restructuring. Curry.


# 30-Aug-24

- Hopefully resolved problems with Multipass 1.14.0 (and RC's), by avoiding `multipass restart`. Using separate `stop` and `start`, instead.
- Moved `usbip` client installation from `rust` -> `rust+emb` instance

# 15-Apr-24

- Toolchain for `web` development (node.js etc.)

# 7-Feb-24

- Unmounting the script folder after install

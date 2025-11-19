# Speed measurements

Details that show, how much Multipass shared mounts are slower than native speed.

// Multipass 1.16.1 (macOS)


## with populated `node_modules`, just scanning

Shared with host:

```
$ time du -h -d 0 node_modules
313M	node_modules

real   0m15.661s
user   0m0.000s
sys    0m1.582s
```

Note that much of the time is spent "somewhere" - not reported by either 'sys' or 'user'.

Mounted to VM-local:

```
$ time du -h -d 0 node_modules
320M	node_modules

real   0m0.773s
user   0m0.052s
sys    0m0.283s
```

## `npm install`, from scratch

Shared with host:

```
$ time npm install
[...]

real	1m29.971s
user	0m23.068s
sys   	0m31.358s
```

Mounted to VM-local:

```
$ time npm install
[...]

real	0m17.716s
user	0m10.029s
sys 	0m9.103s
```

18 vs. 90 seconds: 5 times a speed difference!


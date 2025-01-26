# Track

## Mount problems with 1.14 series

- ["Multipass loses mounts on restart"](https://github.com/canonical/multipass/issues/3642) (opened Aug'24)

	The 1.14 series made changes to how file mounts work. While this aims at higher performance or fixing something, the problems are so severe it has required us to change the way scripting is done (using *native mounts* instead of *classic* mounts in `prep.sh`).
	
	**Added:** Situation remains the same in 1.15.

## Built-in port forwarding

- [Port forwarding](https://github.com/canonical/multipass/issues/309)


# Track

## Mount problems with >= 1.14 series `#multipass`

>*Continues with Multipass 1.15*

- ["Multipass loses mounts on restart"](https://github.com/canonical/multipass/issues/3642) (opened Aug'24)

	The 1.14 series made changes to how file mounts work. While this aims at higher performance or fixing something, the problems are so severe it has required us to change the way scripting is done (using *native mounts* instead of *classic* mounts in `prep.sh`).

>Note: [Replace on MacOS QEMU by Apple VZ](https://github.com/canonical/multipass/issues/3760) may be related? (also below)


## Allow Apple virtualization to be used as a driver `#multipass`

- [Replace on MacOS QEMU by Apple VZ](https://github.com/canonical/multipass/issues/3760)

	>*"If we ever considered this, it would be to replace QEMU entirely [...]"*

Initially, the Multipass team had [bad experience](...) with the Apple Virtualization API. 

However, *maybe* using such would allow e.g. the mount problems (and/or performance on small files?) to be remedied.

>In 2025, Apple's made some releases on [Containerization](https://github.com/apple/containerization): 
>
>*"Swift package for running Linux containers on macOS"*.
>
>- Does this affect Multipass on Mac roadmap, stability, in any measurable way?
>
>Note: *"To build the Containerization package, you need: [...] Mac with Apple silicon"*, i.e. rules Intel-based Macs out.


## FR: Built-in port forwarding `#multipass`

- [Port forwarding](https://github.com/canonical/multipass/issues/309)

Lima does it. Apple Containerization framework likely as well.


<!-- not really tracking; #hidden
## Lima project

Transitioning to [Lima: Linux Machines](https://github.com/lima-vm/lima) could be a possibility if the features / quality of Multipass continues to degrade. <!-- "continues" as in mounts are worse in 1.14+ than in 1.13 -->

- allows use of Apple VZ API (not only QEMU)
- has file sharing and **port forwarding**
-->
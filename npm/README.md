# Node development

Provides:

- `node` (latest even [current version](https://nodejs.org/en/about/previous-releases#release-schedule))
- `npm`

Host side tools:

- `.mp.dive.sh`

	A script to launch one's VM shell session with port fowarding.
	

## Prepare: Host side setup (`security` note!)

The whole point of sandboxing the `npm` environment to a VM is that `npm` modules wouldn't get access to your main account's files (emails, pictures, other documents).

By default, installing `npm` modules do get such access, and your IDE is likely doing this all the time, even without you realizing. It's based on *trusting* the npm module authors that you use (and the modules they use, and so forth...).

Let's plug this, first!

Create a file `~/.npmrc`:

```
package-lock=false
ignore-scripts=true
```

This bans two things for *any* `npm` on your host:

- writes to `package-lock.json`. We'll update the file from the VM, but want to keep it shared.
- running pre/post-install scripts of `npm` packages, thus making `npm install` safe.

After this change, you can no longer debug or run `npm` websites, on your host. Let's set up a VM for that!


## Steps

```
$ npm/prep.sh
...
v24.8.0
11.6.0
```

You now have a working Node / `npm` VM, but we need to do quite a bit of tuning on it, to make things work smooth.

Bare with us: all efforts have been taken to minimize your manual labour. But we just cannot make the setup fully automatic.


### Problem #1: Multipass performance on shared folders degrades if there are lots of small files

We want to share the source code from the host file system, with the VM. 

However, `npm` does not allow moving its `node_modules` folder elsewhere (to a VM-local folder), and leaving it shares grinds performance a *LOT* (like 0.1x speed).

**Countermeasures**

After ensuring there is a `node_modules` folder, we *can* mount it, VM-side, to a local folder.

The target for this is selected to be:

```
~/.cache/node_modules/{project name}
```

This means instead of your `~/abc/node_modules` (for project `abc`, see mounting below), VM will use `~/.cache/node_modules/abc`. 

>[! NOTE]
>This is great also for another reason: the OS'es of your host and VM are different, and this causes binary npm modules to conflict, between the two. Once the host (the IDE) and the VM (actual development 
>environment) use different folders, they'll not stomp on each other.

**What we do automatically**

In the file `custom.mounts.list`, you can define the names of the folders where your `npm` projects' sources are. These will be mapped to the VM, using the last part of the path. Example:

```
# comment
~/Git/averell
/Users/dalt/sources/joe
```

..will cause folders `~/averell` and `~/joe`, VM side.

For these folders, we automatically add lines in the `/etc/fstab` file (VM), allowing them to be user space -mounted on your command:

```
$ cd averell
$ mount node_modules
$ mount .svelte-kit		# if you were to have a SvelteKit project
```

See the contents of `/etc/fstab` if you wish to know the details. Also, if you mount project folders later, manually, copy the entries so your new folders can do the mounts.

The `.svelte-kit` folder is mounted to a memory disk. Its contents don't need to remain over a VM restart.

<details><summary>**Details about the mount options**</summary>

```
/home/ubuntu/.cache/node_modules/averell /home/ubuntu/averell/node_modules none user,bind,noauto,exec,rw,noatime,nodiratime 0 0
/home/ubuntu/.cache/build/averell /home/ubuntu/averell/build none user,bind,noauto,exec,rw,noatime,nodiratime 0 0
sk-averell /home/ubuntu/averell/.svelte-kit tmpfs user,noauto,rw,size=5120k,uid=1000,gid=1000 0 0
```

- `user`: allows you to mount these from user space, without `sudo`
- `noauto`: important so that the mounts won't happen in Linux startup. 

	You cannot do the mounts e.g. in `~/.bashrc` since Multipass adds its mounts only after that.
- `exec`: allows `npm` commands to be executed; crucial
</details>


That's it! 

The mounts are valid as long as your VM runs. If you need to restart it, you will need to redo the mounts. This is a good reason to add them in your `~/.bashrc`.

HOWEVER, just adding `mount` will cause multiple mounts. There's a script in `~/bin/mp-prime.sh` for this purpose. Given a folder name, it checks whether there's already a mount and mounts only if not. Use it if you wish to have the mounts always be enforced by `~/.bashrc`.

<!-- tbd. test the `mp-prime` approach
-->


## Steps (...continued!)

Once the `npm/prep.sh` has finished, you have a VM with `node` and `npm` on it.

```
[host]$ multipass info npm
Name:           npm
State:          Running
Snapshots:      0
IPv4:           192.168.64.219
Release:        Ubuntu 24.04.3 LTS
Image hash:     f1652d29d497 (Ubuntu 24.04 LTS)
CPU(s):         2
Load:           0.00 0.00 0.00
Disk usage:     5.8GiB out of 11.5GiB
Memory usage:   462.3MiB out of 3.8GiB
Mounts:         /Users/dalt/Git/avrell        => /home/ubuntu/avrell
                    UID map: 501:default
                    GID map: 20:default
```

### Problem #2: Hot Module Reload

Not really a problem. :)

Just mentioning that the `CHOKIDAR_USEPOLL` env.var. is defined, within the VM. This is needed for hot-module-reloading to work over network (read: Multipass) mounts. It affects any frameworks built on top of Chokidar (e.g. Vite, and therefore SvelteKit).

Without Hot Module Reload, you need to press "refresh" in the browser, after making changes to your project. With it, the browser can refresh itself.

When using this Multipass setup, you should expect Hot Module Reload (HMR) to just work.


### Problem #3: Exposing the port(s)

Multipass does not do port forwards. If you run development within the VM, and the console asks you to open, say, `http://localhost:3000`, Cmd-double-clicking (macOS) such a link will not work. To have the *host* point to the VM's port, we need port forwarding.

Instead of `multipass shell`, take it as a habit to launch your Multipass sessions with:

```
./.mp.dive.sh
```

Copy this file to your (`npm`) project's file system, and edit it so that the right ports are the defaults. Once set up, all you need to remember is to use it.

>[!NOTE]
>Do study the contents of the said shell script. It copies the private `ssh` key used by Multipass to a location where it can be accessed without `sudo` access rights. You should be aware of this arrangement, though it helps you get it started.

<p />

>**Installing cloud vendor tools (optional)**
>
>Cloud vendor CLI's (command line tools) require authentication. You can do that by setting API tokens (author's favourite), or by signing in to the vendor's web site, from the command line (e.g. `wrangler login`). If you use the latter, make sure that the (somewhat hidden) port used between the CLI and the browser (which runs in host) is forwarded, while you do the login dance.
>
>Or just... use API tokens and you can skip the nonsense.


## Steps (...continued, again)

```
[host]$ PORT=3000 ./.mp.dive.sh
```

Note that the command also tries to cd you to the project folder.

```
$ pwd	# {are you in the project folder?}

$ mount node_modules
$ mount .svelte-kit    # if using SvelteKit
```

```
$ npm install
```

```
$ npm run dev
[...]

  ROLLDOWN-VITE v7.1.13  ready in 4197 ms

  ➜  Local:   http://localhost:3000/
  ➜  Network: http://192.168.64.219:3000/
  ➜  press h + enter to show help

```

✅ This should only take some seconds (see the `4197 ms`, above).

✅ Cmd-double-clicking (on a Mac) the `http://localhost:3000` should work.

✅ Making changes to your web site's sources should refresh the host-side browser (HMR works).


---

Next, you can **deploy** your web project somewhere. For a sample of the steps involved, check the `+wrangler/` subfolder.

---

## Maintenance 

**Updating (within the VM)**
   
```
$ npm install -g npm
```

`npm` will remind you of that, no doubt

>Note: We've made it so that using `npm` doesn't require `sudo` in the sandbox.

**Removing unused disk space**

```
$ npm cache verify
```

Run this occasionally. Keep an eye on your disk space consumption (8GB should be enough, but the `~/.npm` cache does grow..).

Observed savings:

|was -> after `verify`|reclaimed|
|---|---|
|4.3 GB -> 3.7 GB|0.6 GB|
|8.2 GB -> 6.2 GB|2.0 GB|

<!-- #hidden
>Use `multipass info npm` (on the host) to see the available and used disk space.
-->


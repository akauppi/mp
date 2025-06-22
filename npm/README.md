# Node development

Provides:

- `node`
- `npm` 24


## Steps

```
$ npm/prep.sh
```

The `CHOKIDAR_USEPOLL` env.var. is defined, allowing hot-module-reloading to work (over a network mount) for frameworks using chokidar (e.g. Vite).

### Further steps

Unfortunately, Multipass has issues with mounted folders that contains lots of small files. To mitigate these issues - also useful for keeping macOS and Linux binary modules apart - we do some mounts on the VM side.

#### `node_modules`

For **each project folder** you work in:

```
$ openssl rand -hex 4
a888a3f6		<-- use this as a random string; any string will do

$ install -d ~/.node_modules/a888a3f6

# add the lines in `/etc/fstab`:
$ sudo nano /etc/fstab
<<
/home/ubuntu/.node_modules/{..id1..} /home/ubuntu/{..path..}/node_modules none user,bind,noauto,exec,rw,relatime,discard,commit=30 0 0
<<

$ sudo systemctl daemon-reload
```

About the mount options:

- `user`: allows you to mount these from user space, without `sudo`
- `noauto`: important so that the mounts won't happen in Linux startup. You cannot do the mounts e.g. in `~/.bashrc` since Multipass adds its mounts after that.
- `exec`: allows `npm` commands to be executed; crucial

#### `.svelte-kit` (optional)

If your project uses SvelteKit, let's make a cache folder for it. This can be a memory disk (type `tmpfs`).

>Note: For other frameworks, there may be similar cache folders. If you wish to optimize their performance, adopt these steps.

For **each project folder** you work in:

```
$ openssl rand -hex 4
518d730b		<-- use this as a random string; any string will do

$ install -d .svelte-kit

# add the lines in `/etc/fstab`:
$ sudo nano /etc/fstab
<<
{..id2..} /home/ubuntu/{..path..}/.svelte-kit tmpfs user,noauto,rw,relatime,size=5120k,uid=1000,gid=1000,inode64 0 0
<<

$ sudo systemctl daemon-reload
```

#### Using the mounts

Now, once and after each VM restart, do:

```
# within the project folder
$ mount node_modules
$ mount .svelte-kit
```

That's it!  Your `npm` development now works in near-native speed, but within a VM.


## Using: Exposing the port

To have the VM expose its port to outside world (not only its internal `localhost`):

1. Add something like this:

   ```
   // vite.config.js
   export default defineConfig({
      server: {
         host: "0.0.0.0"
      },
   ```

2. Get the VM's IP e.g. from `multipass info npm`. <sup>`|*|`</sup>

   e.g. `192.168.64.85`

You can now open the port in host browser.

<small>`|*|`: It stays the same for each launch, but varies over separate launches.</small>


### Alternatively, forward `localhost`

An alternative (or: parallel) approach is forwarding the VM's `localhost` to the host. Multipass doesn't have built-in port forwarding (Jun'25) and this requires you to keep a terminal open. See [`tools/port-fwd.sh`](./tools/port-fwd.sh) for ideas...


## Using: Installing distribution tools

Cloud vendor CLI's require authentication, and they often involve hooks (from the browser) back to `localhost`. For this to work, you must first proxy the particular port as suggested above. 

Also, there's a sample for `wrangler`, Cloudflare's CLI, within this repo.


## Maintenance 

**Updating (within the sandbox)**
   
```
$ npm install -g npm
```

`npm` will remind you of that, no doubt

>Note: We've made it so that using `npm` doesn't require `sudo` in the sandbox.

**Removing unused disk space**

```
$ npm cache verify
```


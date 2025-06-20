# Node development

For Web development. 
   
Provides:

- `node`
- `npm` 24


## Steps

```
$ npm/prep.sh
```

The `CHOKIDAR_USEPOLL` env.var. is defined, allowing hot-module-reloading to work (over a network mount) for frameworks using chokidar (e.g. Vite).

### Further steps

Unfortunately, Multipass has issues with mounted folders that contains lots of small files. To mitigate these issues - and this is also useful for keeping macOS and Linux binary modules apart - we do some mounts on the VM side.

#### `node_modules`

For **each project folder** you work in:

```
$ openssl rand -hex 4
a888a3f6		<-- use this as a random string; any string will do

$ ID=a888a3f6
$ install -d ~/.node_modules/$ID

# Within the project folder that has 'node_modules'
$ sudo mount --bind ~/.node_modules/$ID node_modules
```

#### `.svelte-kit`

For **each SvelteKit project**:

```
$ touch .svelte-kit

$ sudo mount -t tmpfs -o size=500m,uid=1000 abc .svelte-kit
```

---

These two mounts make sure that small files do not need to be traversed over the host-VM boundary. They remain within the VM, and things work in native speed.

```
{project folder}
	\-- node_modules		--> ~/.node_modules/$ID
	\-- .svelte-kit		--> tmp disk
```

#### Gotchas!!!

The above arrangement works, but is FRAGILE!

1. Mounts cannot be done in `.bashrc` because Multipass mounts happen only after it is processed. Thus, you need to **manually exercise them** for each session.
2. The mounts need to be done after each VM restart: they do not persist. Way to persist them would be using `/etc/fstab` but the author wasn't able to get this working, properly. See `DEVS` folder.
3. The mounts need to be done using `sudo`. While `/etc/fstab` entries allow a user to do a mount, and the mount does work, this arrangement was not compatible with `npm install`, especially or at least `esbuild`. Again, see the `DEVS` folder.

While all this is **annoying** (mostly to the author because he doesn't understand what's wrong), it's... a best effort at this time. You do get native performance. The platform is solid. Just.. two `sudo`s.


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

An alternative (or: parallel) approach is forwarding the VM's `localhost` to the host. Multipass doesn't have built-in port forwarding (Jun'25) and this requires you to keep a terminal open. See [`../tools/port-fwd.sh`](../tools/port-fwd.sh) for ideas...


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


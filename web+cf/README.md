# Web + Cloudflare development

For Web development with Cloudflare as the platform.
   
Has:

- `node` (derived)
- `npm` (derived)

- `wrangler` CLI

## Prelude

>See [`../web/README.md`](../web/README.md) for instructions on the generic tooling.

## Using

Create the VM by:

```
$ web+cf/prep.sh
```

### CLI login

There are two ways to tie your VM terminal to the Cloudflare account:

#### Using `wrangler login`

This is the normally easy way, but doing it from within a VM requires a bit of assistance. It also grants a huge number of access rights to your VM (in order to be easy to use, I guess).

You may try both this and API tokens - and decide what suits you best.

<details><summary>Detailed steps...</summary>

While you do the login dance, the port `8976` of the VM should be visible in your *host* as `localhost:8976`. To accomplish this, we have a help script:

```
$ web+cf/login-fwd.sh
...
```

The script sets up a port forward and instructs you to run the command `wrangler login browser=false` in the VM shell.

Open the provided URL and Cloudflare presents you with this:

>![](.images/login-props.png)

If you ever need to re-authenticate, simply run again the script to have the ports forwarded.
</details>

It's a pretty "whole sale" experience that you grant lots of access at once. You may not need all of them.


#### Login with custom API tokens

Using API tokens allows you *minute* control to what the CLI can - and can not - do. This author prefers this in the long run, since it's always good to run with the minimum set of access rights - especially if you deal with production systems.

Also, some Cloudflare services (e.g. PubSub, as of May'24) [will request you](https://developers.cloudflare.com/pub-sub/guide/#3-fetch-your-credentials) to create a custom access token.

One more plus - no special hoops are needed! :) Just a browser, copy-paste. Done it!

**Creating an API token**

Visit Cloudflare > Dashboard > `My Profile` > [API tokens](https://dash.cloudflare.com/profile/api-tokens).

>![](.images/custom-api-token.png)         

Notice that the first pull-down menu works as a tree structure for the permissions.

Give permissions that you need. You will be able to edit these later, for the same token.

||permission|can|comment|
|---|---|---|---|
|`User`|`User Details`|`Read`|`wrangler whoami` needs this|
|...|

<!-- tbd.
><font color=orange>*tbd.* Add more lines above, once we see where they are needed!</font>
-->

Complete the creation and you'll get a token like `Blah0[...]fuchS`.

>Try it out in the VM:
>
>```
>~$ CLOUDFLARE_API_TOKEN={token here} wrangler whoami
>...
>Getting User settings...
>👋 You are logged in with an API Token, associated with the email {snip}!
>┌───────────────────┬───────────────┐
>│ Account Name      │ Account ID    │
>├───────────────────┼───────────────┤
>│ Outstanding Earth │ ...snip...    │
>└───────────────────┴───────────────┘
🔓 To see token permissions visit https://dash.cloudflare.com/profile/api-tokens
>```

It works.

Add the token in `~/.bashrc` so it gets loaded into the environment at VM restarts.

```
~$ echo CLOUDFLARE_API_TOKEN={token here} >>~/.bashrc 
```

```
~$ . ~/.bashrc
```

Now you are ready to go! 🌞

## Maintenance (CLI)

**Updating (within the sandbox)**
   
```
$ npm install -g wrangler
```

## References

- Cloudflare PubSub > [Fetch your credentials](https://developers.cloudflare.com/pub-sub/guide/#3-fetch-your-credentials)


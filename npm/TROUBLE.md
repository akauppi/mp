# Troubles

## `package-lock.json`

If you have `package-lock.json` enabled (you [don't have to](...tbd. link..)), you will likel see:

```
$ npm run dev

> website@0.0.1 dev
> vite dev

(node:5320) ExperimentalWarning: WASI is an experimental feature and might change at any time
(Use `node --trace-warnings ...` to show where the warning was created)
file:///home/ubuntu/website/node_modules/rolldown/dist/shared/parse-ast-index-BL17IImH.mjs:10700
	if (loadErrors.length > 0) throw new Error("Cannot find native binding. npm has a bug related to optional dependencies (https://github.com/npm/cli/issues/4828). Please try `npm i` again after removing both package-lock.json and node_modules directory.", { cause: loadErrors.reduce((err, cur) => {
	                                 ^

Error: Cannot find native binding. npm has a bug related to optional dependencies (https://github.com/npm/cli/issues/4828). Please try `npm i` again after removing both package-lock.json and node_modules directory.
    at file:///home/ubuntu/website/node_modules/rolldown/dist/shared/parse-ast-index-BL17IImH.mjs:10700:35
    at ModuleJob.run (node:internal/modules/esm/module_job:371:25)
    at async onImport.tracePromise.__proto__ (node:internal/modules/esm/loader:702:26)
    at async CAC.<anonymous> (file:///home/ubuntu/website/node_modules/vite/dist/node/cli.js:571:27) {
  [cause]: Error: Cannot find module '@rolldown/binding-linux-x64-gnu'
  Require stack:
  - /home/ubuntu/website/node_modules/rolldown/dist/shared/parse-ast-index-BL17IImH.mjs
      at Module._resolveFilename (node:internal/modules/cjs/loader:1420:15)
      ... 6 lines matching cause stack trace ...
      at require (node:internal/modules/helpers:152:16)
      at requireNative (file:///home/ubuntu/website/node_modules/rolldown/dist/shared/parse-ast-index-BL17IImH.mjs:10471:20)
      at file:///home/ubuntu/website/node_modules/rolldown/dist/shared/parse-ast-index-BL17IImH.mjs:10669:17 {
    code: 'MODULE_NOT_FOUND',
    requireStack: [
      '/home/ubuntu/website/node_modules/rolldown/dist/shared/parse-ast-index-BL17IImH.mjs'
    ],
    cause: Error: Cannot find module '../rolldown-binding.linux-x64-gnu.node'
    Require stack:
    - /home/ubuntu/website/node_modules/rolldown/dist/shared/parse-ast-index-BL17IImH.mjs
        at Module._resolveFilename (node:internal/modules/cjs/loader:1420:15)
        at defaultResolveImpl (node:internal/modules/cjs/loader:1058:19)
        at resolveForCJSWithHooks (node:internal/modules/cjs/loader:1063:22)
        at Module._load (node:internal/modules/cjs/loader:1226:37)
        at TracingChannel.traceSync (node:diagnostics_channel:322:14)
        at wrapModuleLoad (node:internal/modules/cjs/loader:244:24)
        at Module.require (node:internal/modules/cjs/loader:1503:12)
        at require (node:internal/modules/helpers:152:16)
        at requireNative (file:///home/ubuntu/website/node_modules/rolldown/dist/shared/parse-ast-index-BL17IImH.mjs:10466:11)
        at file:///home/ubuntu/website/node_modules/rolldown/dist/shared/parse-ast-index-BL17IImH.mjs:10669:17 {
      code: 'MODULE_NOT_FOUND',
      requireStack: [
        '/home/ubuntu/website/node_modules/rolldown/dist/shared/parse-ast-index-BL17IImH.mjs'
      ]
    }
  }
}
```

Scroll right, and you see it saying:

```
Please try `npm i` again after removing both package-lock.json and node_modules directory.
```

```
$ rm package-lock.json
$ rm -rf node_modules/* node_modules/.*
```

**Countermeasures**

While your IDE and the VM use different `node_modules` folders, they'll still compete for who last wrote the `package-lock.json`!

The way the author counter-acts this is (on host):

```
$ more ~/.npmrc 
# No 'package-lock.json' from the host side
package-lock=false
```

That may be a bit harsh. The nice part is that it works throughout any IDE's, as long as their `npm` reads the ´~/.npmrc` file.

And the change doesn't dictate anything to the projects - now some of them may have `package-lock.json` enabled, others not. It remains a *VM side* detail.

>There may be other ways around this. Let the author know about yours - perhaps we'll add it here.

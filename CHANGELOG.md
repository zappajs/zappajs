**0.4.7** (2012-08-25)

  * Added `@req` and `@res` to the handler. (#20, end)
  * Use `real_root` to locate modules to be included (#34)
  * Working scenario for separate Express and Socket.IO servers. (#32)
  * Renamed example/assets.coffee into examples/connect-assets.coffee

**v0.4.6** (2012-08-15)

  * Added `@req` and `@res` due to popular demand. (#20)
  * Changed `@app.server` into `@server`.
  * Added support for `coffee-css` in `@css`.

  * Added `connect-assets` examples (#18) @scien
  * Corrected documentation: `serve jquery` and `serve sammy` are obsolete. (#27)
  * Website: require('zappajs'), not 'zappa' @audreyt #31

**v0.4.5** (2012-08-13)

  * Updated dependencies to current versions.
  * Updated jquery to 1.8.0.
  * Updated examples.
  * Fixed postrender.
  * Added test for socket.io.js.
  * Corrected bugs introduced by abusive use of `arguments`.
  * Corrected `broadcast_to` for socket.io post-0.7
  * `broadcast_to_all` doesn't exist (`broadcast_to` already broadcasts to self)
  * Corrected socket.io rooms test

**v0.4.4** (2012-08-09)

  * Re-published since 0.4.3 was missing `lib` and `vendor`.

**v0.4.3** (2012-07-30)

  * Re-introduced support for partials (`@use 'partials'`)
  * Corrected tests

**v0.4.2** (2012-06-22)

  * Reverted previous `view` changes (from v0.4.0); implemented ZappaFS. (#7)
  * In Express 3.x the view can no longer modify its environment.
  * Initial documentation test suite.
  * Fixed zappa.app options defaults.

**v0.4.1** (2012-06-19)

  * Added `partial` (#23)

**v0.4.0** (2012-06-18)

  * Added Express 3 support (#7)

**v0.3.9** (2012-06-05):

  * Added support for https server.
  * Added test for rooms (#4).
  * Added test for @ack
  * Updated jsdom & socket.io-client
  * Updated examples so that they can be used for testing.
  * Bumped socket.io to 0.9.x fix #21 [Radagaisus]

**v0.3.8** (2012-05-30):

  * Added examples for connect-assets usage. (#18) [scien]
  * Added support for route middleware (solves #11).
  * Added support of non-function helpers [grncdr]
  * Unified helpers application.
  * Made crashcourse.md compatible with git-markdown (#19) [edubkendo]
  * Documentation update and cleanup.

**v0.3.7** (2012-05-25):

  * Chatroom example [scien]
  * Added generic CSS template module support
  * Added support for socket.io acknowledgments [Radagaisus]
  * Made @include work with require'd modules [imzshh]
  * Added option to disable socket.io [scien]

**v0.3.6** (2012-04-24):

  - Migrated to coffeecup, closes #1
  - Closed mauricemach/zappa#122 [cap10morgan]
  - Closed mauricemach/zappa#103 [timshadel]
  - Closed mauricemach/zappa#124 [Evangenieur]
  - Updated documentation

**v0.3.5** (2012-04-17):

  - Updated documentation
  - Updated to jquery 1.7.2 and sammy 0.7.1
  - Closed mauricemach/zappa#116 [jacobrask]
  - Closed mauricemach/zappa#123 [imzshh]
  - Closed mauricemach/zappa#117 [scien]

**v0.3.4** (2012-04-16):

  - Publishing as `zappajs`.
  - Workaround for express 3.0.0alpha1.

**v0.3.3** (2011-11-22):

  - Fixed npm publishing error.

**v0.3.2** (2011-11-22):

  - Changed: `@enable 'serve zappa|jquery|sammy'` replaced by `@use 'zappa'`. Closes #94.
  - Updated to work with express 2.5.x and node 0.6.x.

**v0.3.1** (2011-10-06):
)
  - Changed dependency minors to ".x". Closes #98.

**v0.3.0 "The Gumbo Variations"** (2011-09-29):

  - Changed: "magic locals" replaced by properties of `this` (`get` becomes `@get`). See #74 and the [announcement](http://zappajs.org/docs/0.3-gumbo/announcement).
  
  - Backtraces now show the relevant file and (js) file number.
  
  - Normal JS scope restored: `def`, `zappa {foo}, ->` etc gone.
  
  - Changed: automatic input "importing" and "exporting" to templates now optional through the `databag` setting. See #84.
  
  - Changed: removed hard dependency on `jsdom`. To use `@postrender`, `npm install jsdom` first.

**v0.2.1** (2011-09-22):

  - Changed: using standard jquery from code.jquery.com instead of node-jquery. Updated to 1.6.4.
  
  - Changed: updated sammy to 0.7.0.
  
  - Fixed #80: Default layout is not being added correctly.

**v0.2.0 "Peaches en Regalia"** (2011-09-08):

  - Changed: externals (`zappa {foo} ->`) are available at all scopes, shadow globals and root scope locals.
  
  - Fixed: inline templates with multiple apps.
  
  - Added `stylus` to the root scope (compiles string with stylus and serves it as css).
  
  - Fixed #58: multiple socket events fail. Also applied the same fix to helpers.
  
  - Changed `zappa.run` to interpret a number-castable string param as the port, to better integrate with Heroku. Closes #61 [Tim Shadel]
  
  - Fixed #64: require does not pick up node_modules in app dir. [Jason King]
  
  - Added: setting views dir to `__dirname + '/views'` by default. Closes #71. [rachel-carvalho]
  
  - Added the `minify` setting, which uses uglify-js to minify the outputs of `serve zappa`, `client`, `shared`, `coffee` and `js`. Closes #70 (thanks @jacobrask).
  
  - Added back `session` to the request handlers scope. [shimaore]

**v0.2.0beta** (2011-08-02):

  - Complete rewrite, see `/docs/peaches.md` for a more in-depth review on changes.
  
  - Fixed performance, now negligible overhead on top of express. Gone with the `with` keyword.

  - Scraped the `zappa` command, zappa code should go in `require('zappa') ->` blocks. All node tools and services can be used directly.

  - Changed `include`, now implemented through standard module mechanisms. Code to be included must be exported: `@include = ->`.

  - Added `app` and `io` variables to all scopes, providing direct access to express and socket.io.
  
  - Added optimized interfaces to express features such as `use`, `set`, `enable`, `disable`, `configure`, etc.
    
  - Changed `render`, now uses the rendering system from express, with all its features. Defining inline templates with `view` and passing variables through `@` is still possible.
    
  - Added an optional client-side API that can be used with `client`. To just serve code as JS, use `coffee`.
  
  - Added `shared`, allows sharing code between client and server.
  
  - Removed most zappa's defaults, added very concise APIs to define what you need.

**v0.1.5** (2011-05-06):

  - Reworked packaging for npm 1.x.

**v0.1.4** (2011-01-05):

  - Updated to CoffeeScript 1.0.0 and node 0.2.6/0.3.3.
  - Soda tests by Nicholas Kinsey.
  - `broadcast` passing along optional `except` param to socket.io.
  - Empty app files now start a default "blank" app, serving files at /public.
  - `zappa -n/--hostname` to listen on a specific hostname or IP.
  - Made defs available to postrenders' scope.
  - Bug fixes.

**v0.1.3** (2010-11-24):

  - Updated to CoffeeScript 0.9.5 and node 0.2.5/0.3.1.
  - Partials support.
  - Compilation to .js file with `zappa -c`.
  - Auto-restarting on changes with `zappa -w`.

**v0.1.2** (2010-11-13):

  - Multiple `using`'s: `using 'foo', 'bar', 'etc'`.
  - Added `layout: no` option to `render`.
  - Added `require` at the root level and `send` at the request level (shortcut to `request.send`).
  - bodyDecoder, cookieDecoder and session middleware by default. Configs to turn them off will follow.
  - Using new jQuery (1.4.3) npm package instead of jsdom directly.
  - Using Socket.IO 0.6.0 (great improvements over the previous version).

**v0.1.1** (2010-10-22):

  - Fixed ws connection/disconnection handler implementation.
  - Fixed ws render implementation.
  - Fixed postrender implementation.
  - Ports specified at the zappa command or the `.run` method, instead of the `port` function.
  - Added a default layout.
  - Added `style`.

**v0.1.0 "Jazz from Hell"** (2010-10-21):

  - Initial release.

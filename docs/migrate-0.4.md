---
layout: default
title: Migration to ZappaJS 0.4
---

Zappa 0.4 uses Express 3.0 while Zappa 0.3 uses Express 2.5.
The new version of Express is not backward-compatible and breaks
Zappa in places. Here are the differences we know about.

* Most template engines do not support the new Express 3.x conventions at this
  time; if you want to use them you should for example:

      @engine 'eco', require('consolidate').eco

  or (works alongside Zappa's `databag` option)

      @engine 'eco', zappa.adapter 'eco'

  Since `register` was removed in Express 3.x it is therefor no longer
  available in Zappa 0.4.

* Layout and partials support was removed from Express 3.x, and is no longer
  available in vanilla zappa 0.4.

  To continue using `layout` or partials in zappa 0.4 you must

      @use 'partials'

  This will require that you have the `zappa-partials` module installed in
  your application. (This module is an extended version of
  `express-partials` with support for multiple instances, pending integration
  in mainline.)

* Express 3.0 is no longer a subclass of the Node.js HTTP server. The server
  object is available as `@server`; `@app.listen` is now
  `@server.listen`.

* Express 3.0 split `json` and `jsonp`. If your code used `json` for `jsonp` this won't work anymore, make sure to migrate those calls to use `jsonp`.

Other changes are Zappa-specific and simplify the API:

* If you built variadic helpers in Zappa 0.3 you might have been aware of an undocumented,
  extraneous parameter (the context) provided to the helpers.

  That extraneous argument has been removed since it is a duplicate of `this`.
  Helper functions now receive the arguments provided by the caller unmodified.

* No argument (the databag or context) are passed to callbacks.

  This might apply to you if you used the `databag` option (see below) or you used the context
  argument instead of `this`.

  This applies to (server-side) `@get`, `@post`, `@put`, `@del`, `@all`, all middleware functions,
  and `@on`.
  This applies to (client-side) `@get` (use `@params`) and `@on` (use `@data`).

  For example, if your code said:

      @get '/': (context) ->
        context.params

  replace it with

      @get '/': ->
        @params  # or this.params

* The `databag` option has been modified.
  * It is now a boolean, use `@enable 'databag'` to activate it.
  * The databag is available as `params` (`@params` in coffeecup) to views.
    This is its only documented use.
  * All callbacks are called the same way whether databag is enabled or not.
    Callbacks no longer receive the context (`@`) or the databag as an argument.
  * If enabled, the databag is available as `@data` in request handlers and
    request middleware, but it is more efficient to use `@req.param(name)` than
    `@data.name`, since building the databag might be an expensive operation.
    Also `@req.param()` is available whether the `databag` setting is enabled or not.
  * If you were using the object created by the `databag` setting:
    * Server-side, for `@get`, `@post`, ... and for middleware use `@req.param()`.
      For `@on` use `@data`.
    * Client-side, for `@get` use `@params`, and for `@on` use `@data`.
  * The `param` option value for the `databag` setting is now the *enabled* state of the `databag` setting.
  * The `this` option value for the `databag` setting has been removed.

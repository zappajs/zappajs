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

---
layout: default
title: API Reference (v4.0)
---

# {{page.title}}

## References

For a list of standard middleware, see [the Connect documentation](https://github.com/senchalabs/connect#middleware).

A lot of Zappa methods are shortcuts or extensions of the [Express API](http://expressjs.com/4x/api.html).

## Debug

Zappa uses [`debug`](https://github.com/visionmedia/debug) with the `zappajs` name.

## EXPORTS

`require 'zappajs'` returns a function with the following attributes:

### zappa.app

    zappa.app function [, options]

    zappa.app [options ,] function

Builds an app with express/socket.io, based on the function you provided.

The function you provided will be called with the value of `this`/`@` set to an object with all the attributes described in the **root scope** section.

You might also provide an object containing options, see their description in the following section.

Returns the **root scope**.

### zappa.run

    zappa.run [port,] [host,] [options,] function

or, simply:

    zappa [port,] [host,] [options,] function

Same as `zappa.app`, but calls `server.listen` for you. To know when the server is ready, listen for the `listening` event on the `server` field of the **root scope**.

    z = require('zappajs') ->
      @get '/': 'hi'

      @server.on 'listening', ->
        console.log 'Server started.'

    z.server.on 'listening', ->
      console.log 'Server started too!'

This is especially useful when writing tests that use Zappa.

If you enabled debug, the following message will be printed:

    Express server listening on <ip>:<port> in [development/production] mode
    Zappa x.x.x orchestrating the show.

As noted, the base export is actually a reference to `zappa.run`, so these are equivalent:

    require('zappajs').run ->
      @get '/': 'hi'

    require('zappajs') ->
      @get '/': 'hi'

You can pass the parameters in any order. Number is port, string is host, object is options, and function is your application. Port and host are optional. Omitted params will also be omitted in the `server.listen` call to express (defaulting to port 3000 and binding to `INADDR_ANY`).

You can also pass the parameters in the `options` object. The following options are available:

* `port`
* `host`
* `io`: options for the Socket.IO server. Set to `false` to disable Socket.IO.
* `https`: object containing [options for HTTPS](http://nodejs.org/api/tls.html#tls_tls_createserver_options_secureconnectionlistener). Generally `key` and `cert` are all you need:

        # Start a HTTPS server on port 443
        require('zappajs') 443, https:{ key: ... , cert: ... }, ->
          @get '/': 'hi'

The following options are available, but using them will void your warranty:

* `express`: override the default express module with this one.
* `socketio`: override the default Socket.io module with this one.
* `seem`: override the default async module (for example if you'd rather use [`co` v4](https://www.npmjs.com/package/co) than [`seem`](https://www.npmjs.com/package/seem)).

### zappa.version

Version of zappa running.

## ROOT SCOPE

The function you pass to `zappa.app` or `zappa.run` will be called with `this`/`@` set to an object with the following attributes:

### @get, @post, @put, @delete, @head, @patch, .., @all

    @get '/path': handler

    @get '/path', middleware, ..., handler

Define handlers for HTTP requests.

Shortcuts to express' `app[verb]`. Params will just be passed forward unmodified (except for the handler functions, which will be re-scoped), unless a single object is passed. In which case, each key in the object will be a route path, and the value its respective handler. The handler can be a function or a string. In the latter case, the handler passed to express will be a function that only calls `res.send` with this string.

The handler functions will have access to all variables described in the **request handlers scope** section. The middleware functions can also get access to those variables, but for performance reasons this is not enabled by default, use `@wrap` to give them access.

If a handler returns a string, `res.send(string)` will be called automatically.

If a handler returns a generator, that generator will be assumed to be an async function and will be passed through `seem` to yield a result.

If a handler returns a Promise and that Promise's value is a string, `res.send(string)` is called on the value. If the Promise is rejected, the error is passed down to `next` instead of being hidden.

Handlers which are neither functions nor strings will generate an exception.

Ex.:

    @get '/': 'hi'

    @get '/', -> 'hi'

    @get /regex/, -> 'hi'

    @get '/': 'hi', '/wiki': 'wiki', '/chat': 'chat'

    @get
      '/': -> 'hi'
      '/wiki': 'wiki'
      '/chat': -> @response.send 'chat'

Assuming `user_db.get` and `group_db.get` are async and return Promises.

    @get '/user/:name', ->
      user = yield user_db.get @params.name
      group = yield group_db.get user.group
      @json {user,group}

Example using a Route Middleware

    load_user = @wrap ->
      user = users[@params.id]
      if user
        @request.user = user
        @next()
      else
        @next "Failed to load user #{@params.id}"

    @get '/:id', load_user, -> 'hi'

Or using the alternate syntax (the route handler is the last element in the array):

    @get '/:id': [load_user, -> 'hi']

You can pass middleware arrays using Coffee-Script's `...` splats as well, for better readability:

    common = [auth, load_user, apply_policy]

    @get '/:id', common..., -> 'hi'

Or as plain arrays, as Express allows:

    common = [auth, load_user, apply_policy]

    @get '/:id', common, -> 'hi'

Or using the alternate syntax (route handler last element in the array):

    @get '/:id': [common, -> 'hi']

Finally, the original arguments are available as regular function parameters if for some reason you'd rather do that:

    @get '/': (req,res,next) -> 'hi'

### @on

    @on event: handler

Define handlers for events emitted by the client through socket.io.

Shortcut to socket.io's `socket.on 'event'`.

The handler functions will have access to all variables described in the **socket handler scope** section. They won't have access to their parent scope. To make variables available from the parent scope to these handlers, use `helper`.

If a handler returns a generator, that generator will be assumed to be an async function and will be passed through `seem` to yield a result.

Some standard events are generated automatically by Socket.IO: `connection`, `disconnect`.

### @helper

Helpers content is made available to both the [request handler](#request-handler-scope) and [socket handler](#socket-handler-scope) scopes.

When you create a helper with the name `name`, the content of the helper is available as `@name` in the [request handler scope](#request-handler-scope) and the [socket handler scope](#socket-handler-scope).

#### @helper (data)

    @helper name: data

The helper will provide the associated data.

#### @helper (function)

    @helper name: function

A function that will be available to both the request handler and socket handler scopes. It will have access to the same variables as whatever called it. Ex.:

    @get '/': ->
      @sum 5, 7

    @on connection: ->
      @sum 26, 18

    @helper sum: (a, b) ->
                            # Values when called from `@get` vs `@on`
      console.log a         # 5 vs 26
      console.log @request  # available vs undefined
      console.log @emit     # undefined vs available

Since the parameter is actually an object, you can define any number of helpers in one go:

    @helper
      sum: (a, b) -> a + b
      subtract: (a, b) -> a - b

### @view

    @view path: contents

Define an inline template. That template is made available to [`@render`](#render) inside the route handlers.

Ex.:

    {h1} = @teacup
    @view index: ->
      h1 @foo

    @view 'index.eco': '''
      <h1><%= @foo %></h1>
    '''

By default, the templating engine is teacup with extension `.coffee`. Since teacup is just coffee-script, you might use any coffee-script construct in your views:

    {ul,li} = @teacup
    @view index: ->
      ul =>
        for item in @items
          li item

The parameters are also available explicitely:

    {ul,li} = @teacup
    @view index: ({items}) ->
      ul =>
        for item in items
          li item

To use other engines, just use express' mechanisms:

    @render 'index.jade'

Or:

    @set 'view engine': 'jade'

### @include (file)

    @include "file"

Will `require` the file at the path specified, and run a function exported as `include` against the same scope as the current function.

    # app.coffee
    require('zappajs') ->
      @foo = 'bar'
      ping = 'pong'
      @get '/': 'main'
      @include './sub'

    # sub.coffee
    @include = ->
      console.log @foo    # 'bar'
      console.log ping    # error
      @get '/sub': 'sub'

### @include (module)

    @include require "module"

Allows to `require` arbitrary modules (using the standard Node.js algorithm). The module must export a function named `include`.

This allows you to package your Zappa components in modules and locate them automatically.

### @include (file|module) args...

The extraneous arguments are passed as-is to the `@include` function.
This can be used with both the `file` and the `module` versions of `@include`.

For example:

    # app.coffee
    require('zappajs') ->
      @include './sub', auth, foo

    # sub.coffee
    @include = (auth,foo) ->
      @get '/', auth, ->
        @json foo

### @browserify

    @browserify '/foo.js': ->

      @on welcome: ->
        console.log 'A socket.io event.'

Serves the function, [browserified](http://browserify.org/), as `/foo.js`, with content-type `application/javascript`.

Notice that since we cannot retrieve the original CoffeeScript code from the Javascript compiled version, there could be conflicts with the helper functions' names. Therefor avoid using the following names as variables: `slice`, `hasProp`, `bind`, `extend`, `ctor`, `indexOf`, and `modulo`.

This function is particularly useful to build client-side application that require the [`zappajs-client`](https://github.com/zappajs/zappajs-client) module:

    @browserify '/app.js', ->
      Debug = require 'debug'
      Debug.enable '*'

      pkg = require './package.json'
      debug = Debug "#{pkg.name}:bar"

      debug 'Starting client'
      Zappa = require 'zappajs-client'

      Zappa ->

        @on 'server-said', (data) ->
          @emit 'ok', data+4

But obviously this might work for any of your client-side needs:

    @browserify '/with-jquery.js', ->

      $ = require 'component-dom' # did you expect something else?!

You can still use [`browserify-middleware`](https://www.npmjs.com/package/browserify-middleware) to build bundles from independent source files:

    Browserify = require 'browserify-middleware'
    # You may explicitely set the dependencies via `settings`
    Browserify.settings transform: ['coffeeify']
    # or use [`browserify.transform` in your `package.json`](https://github.com/substack/node-browserify#browserifytransform).

    # It would be nice to have this as the default `engine` in ZappaJS.
    @get '/my-app.js', Browserify './client/app.coffee'

### @coffee

    @coffee '/foo.js': ->
      alert 'hi!'

Serves `";#{coffeescript_helpers}(#{your_function})();"` as `/foo.js`, with content-type `application/javascript`.

Notice that since we cannot retrieve the original CoffeeScript code from the Javascript compiled version, there could be conflicts with the helper functions' names. Therefor avoid using the following names as variables: `slice`, `hasProp`, `bind`, `extend`, `ctor`, `indexOf`, and `modulo`.

### @js

    @js '/foo.js': '''
      alert('hi!');
    '''

Serves the string as `/foo.js`, with content-type `application/javascript`.

### @css (object parameter)

    border_radius = (radius) ->
      WebkitBorderRadius: radius
      MozBorderRadius: radius
      borderRadius: radius

    font_size = '12px'

    @css '/foo.css':
      body:
        font: "#{font_size} Helvetica, Arial, sans-serif"

      'a.button':
        border_radius '5px'

Serves the object, compiled with [coffee-css](https://github.com/khoomeister/coffee-css), with content-type `text/css`.

Since coffee-css is just coffeescript, you might use any coffeescript construct in your CSS.

### @css (string paramater)

    @css '/foo.css': '''
      body { font-family: sans-serif; }
    '''

Serves the string as `/foo.css`, with content-type `text/css`.

### @use

Shortcut to `@app.use`. It can be used in a number of additional ways:

It accepts multiple parameters:

    @use (require 'body-parser').urlencoded(), (require 'cookie-parser')()

Strings:

    @use 'cookie-parser'

And objects:

    @use
      static: __dirname + '/public'
      session:
        secret: 'fnord'

When passing strings and objects, zappa's own middleware will be used if available, or express (connect) middleware otherwise. (See below for a description of zappa's middlewares.)

Tip: middleware added with `@use` will be ran for every request. If you only want some requests to use a specific middleware, use the route-middleware syntax: `@get '/path', middleware1, middleware2, -> ...`

When passing functions, those function might use the Express API:

    @use (req,res,next) ->
      res.locals.user = 'foo'

or they might be wrapped to use the Zappa API:

    @use @wrap ->
      @locals.user = 'foo'

Available zappa middleware are `static` and `session`:

#### static

This zappa middleware uses the [Connect static middleware](http://www.senchalabs.org/connect/static.html) to serve static files.

Same as `@express.static(root + '/public')`, where `root` is the directory of the first file that required zappa.

    @use 'static'
    @use static: abs_path
    @use static: {path: abs_path, maxAge: 60}

#### session

This zappa middleware is a wrapper for [`express-session`](https://www.npmjs.com/package/express-session). Use it instead of `express-session` to enable access to ExpressJS' `@session` inside your Socket.io code.

The Express session-store saved by this middleware is available in ZappaJS' root scope as `@session_store`.

    ExpressRedisStore = (require 'connect-redis') @session
    @use session: new ExpressRedisStore redis_config

### @wrap

Wraps a middleware function so that it supports both the Express API and the Zappa API:

    # Middleware written using the Zappa API: must be wrapped
    mw = @wrap ->
      @locals.user = @query.user

    # Middleware using the Express API: wrapping is optional
    mw = (req,res,next) ->
      res.locals.user = req.query.user

    # Both can be used with `@use`
    @use mw

    # Or as route middleware
    @get '/user', mw, ->
      @send @locals.user

### @set

Shortcut to [`@app.set`](http://expressjs.com/en/4x/api.html#app.set). Accepts an object as param. Ex.:

    @set foo: 'bar', ping: 'pong'

See the section on [`APP SETTINGS`](#app-settings) at the bottom of this document for Zappa-specific settings.

### @enable

Shortcut to [`@app.enable`](http://expressjs.com/en/4x/api.html#app.enable). Accepts multiple params in one go. Ex.:

    @enable 'foo', 'bar'

See the section on [`APP SETTINGS`](#app-settings) at the bottom of this document for Zappa-specific settings.

### @disable

Shortcut to [`@app.disable`](http://expressjs.com/en/4x/api.html#app.disable). Accepts multiple params in one go. Ex.:

    @disable 'foo', 'bar'

See the section on [`APP SETTINGS`](#app-settings) at the bottom of this document for Zappa-specific settings.

### @engine

Similarly to Express [`@app.engine`](http://expressjs.com/en/4x/api.html#app.engine), allows to register specific template engines.

This is normally not needed unless you want to change the behavior of the engine.

Accepts an object as param. Ex.:

    @engine eco: require 'eco'

Note that most template engines do not natively support the new Express 3.x/4.x conventions at this time, use the [consolidate](https://github.com/visionmedia/consolidate.js) package to work around this:

    @engine 'eco', require('consolidate').eco

### @locals

Shortcut to [`@app.locals`](http://expressjs.com/en/4x/api.html#app.locals). The values set in `app.locals` are available to all templates.

### @param

    @param name:callback,...

Shortcut to [`@app.param`](http://expressjs.com/en/4x/api.html#app.param). The callback is triggered when the route contains the param `name`.
Accepts multiple params in one go.

The callback is scoped identically to a request handler: you do not need to apply `@wrap`.
Additionally `@param` is assigned the value of the parameter.

    @param 'user_id', ->
      if not @param.indexOf /^[0-9A-F]{24,24}$/i
        @next "Invalid User ID"
      else
        @next()

### @with

This is a Zappa extension. The following options are supported.

#### @with css

`@with css:'cssmod'`

Add a new function named `cssmod` to the [root scope](#root-scope). That function serves CSS compiled from the specified module. Here are two examples with `stylus` and `less`:

    @with css:'stylus'

    @stylus '/foo.css': '''
      border-radius()
        -webkit-border-radius arguments
        -moz-border-radius arguments
        border-radius arguments

      body
        font 12px Helvetica, Arial, sans-serif

      a.button
        border-radius 5px
    '''

Compiles the string with [stylus](http://learnboost.github.com/stylus) and serves the results as `/foo.css`, with content-type `text/css`.

You must have stylus installed with `npm install stylus`.

    @with css:'less'

    @less '/foo.css': '''
      .border-radius(@radius) {
        -webkit-border-radius: @radius;
        -moz-border-radius: @radius;
        border-radius: @radius;
      }

      body {
        font: 12px Helvetica, Arial, sans-serif;
      }

      a.button {
        .border-radius(5px);
      }
    '''

Compiles the string with [less](http://lesscss.org/) and servers the results as '/foo.css', with content-type `text/css`.

You must have less installed with `npm install less`.

### @zappa

The same object that is exported when you `require 'zappa'`.

### @express

The object returned by `require 'express'`.

### @io

The object returned by `require('socket.io').listen`.

### @app

The object returned by `express()`.

[Express Application API](http://expressjs.com/api.html#application)

### @teacup

A shortcut to the [`teacup`](http://goodeggs.github.io/teacup/) module.

### @id

A unique UUID generated for this zappa instance.

## REQUEST HANDLER SCOPE

The function you pass to `@get`, `@post`, etc., will be called with `this`/`@` set to an object with the following attributes.
These attributes are also available to functions passed to `@param`, unless specified otherwise.
These attributes are also available to `@wrap`ped middleware functions, unless specified otherwise.

### @response

Directly from express.

Shortcut: `@res` is a synonym for `@response`.

[Express Response API](http://expressjs.com/api.html#response)

### @request

Directly from express.

Shortcut: `@req` is a synonym for `@request`.

[Express Request API](http://expressjs.com/api.html#request)

### @next

Directly from express. This is normally used in middleware code.

Use `@next "error message"` to propagate an error message down the Express pipeline.
Use `@next()` to continue processing and call the next middleware/handler.

### @query

Shortcut to [`@request.query`](http://expressjs.com/en/4x/api.html#req.query)

The parameters listed after `?` in the URI.

### @body

Shortcut to [`@request.body`](http://expressjs.com/en/4x/api.html#req.body)

This might be the raw body or a parsed body if you used a body-parsing middleware.

### @params

Shortcut to [`@request.params`](http://expressjs.com/en/4x/api.html#req.params)

The parameters found in the URI path, for example

    @get '/user/:name', ->
      @params.name

### @session

Shortcut to [`@request.session`](https://github.com/expressjs/session#reqsession).

### @locals

Shortcut to [`@response.locals`](http://expressjs.com/en/4x/api.html#res.locals).

### @send

Shortcut to [`@response.send`](http://expressjs.com/en/4x/api.html#res.send).
Not available in param handlers.

### @json

Shortcut to [`@response.json`](http://expressjs.com/en/4x/api.html#res.json).
Not available in param handlers.

### @jsonp

Shortcut to [`@response.jsonp`](http://expressjs.com/en/4x/api.html#res.jsonp).
Not available in param handlers.

### @render

Shortcut to [`@response.render`](http://expressjs.com/en/4x/api.html#res.render).
Not available in middleware and param handlers.

Adds the following features:

  - You can use the syntax: `@render name: {foo: 'bar'}`.

  - You can use inline views (see [`@view`](#view)).

### @redirect

Shortcut to [`@response.redirect`](http://expressjs.com/en/4x/api.html#res.redirect).
Not available in param handlers.

### @format

Shortcut to [`@response.format`](http://expressjs.com/en/4x/api.html#res.format), used for content negotiation.
Not available in param handlers.

Example:

    @get '/clients/:id':
      client = retrieve_client @params.id
      @format
        text: =>
          @send client.name
        html: =>
          @render 'client', client
        json: =>
          @json client
        'image/png':
          qr_encode client

### @emit

Send a Socket.IO message to the local socket.

    @emit 'message', data

    @emit 'message', data, (ack_data) ->
      console.log 'Client acknowledged with data'

If the `ack` handler returns a generator, that generator will be assumed to be an async function and will be passed through `seem` to yield a result.

The local socket was automatically referenced using the channel-name `__local` if using the ZappaJS client.

## SOCKET HANDLER SCOPE

The function you pass to `@on` will be called with `this`/`@` set to an object with the following attributes:

### @socket

Directly from socket.io.

### @data

Directly from socket.io. The data sent by the client in the message.

### @ack

Directly from socket.io. Used to provide acknowledgement of messages sent by `@emit` on the client.

    @on start: ->
      console.log @data # 'now'
      @ack 'Got it!'

    @browserify '/index.js', ->
      ZappaClient = require 'zappajs-client'

      ZappaClient ->
        @emit start: 'now', ->
          alert @data  # 'Got it!'

### @id

Shortcut to `@socket.id`.

### @client

An empty object unique for each socket. You can put data pertaining to the client here, as an alternative to `@socket.set`.

### @emit

    @emit 'event'
    @emit 'event', {key:value}

Shortcut to `@socket.emit`. Send a message to the client.

Adds the following features:

  - You can use the syntax: `@emit name: {foo: 'bar'}`.

### @broadcast

Shortcut to `@socket.broadcast`. Send a message to all clients except ours.

Adds the following features:

  - You can use the syntax: `@broadcast name: {foo: 'bar'}`.

### @join

    @join room

Shortcut to `@socket.join`.

### @leave

    @leave room

Shortcut to `@socket.leave`.

### @broadcast_to

    @broadcast_to room, msg

Shortcut to `@io.sockets.in(room).emit`.

Broadcast to a room.

### @session

If available, the Express session object associated with the Socket.io socket.

The session object is only available _after_ the Socket.IO socket has been associated with the Express session; it is especially *not* available inside `@on connection` since at that time the client hasn't had an opportunity to process the association.

The association is done automatically for the default, local Express session and local Socket.IO server by [`zappajs-client`](https://github.com/zappajs/zappajs-client#usage). `zappajs-client` also allows you to specify a separate Socket.IO server, in which case it will automatically associate that server's session with the current ExpressJS session.

Note: You must use Zappa's `@use session:....` instead of directly calling `@use 'express-session'` if you plan to use this feature.

See `examples/share_*.coffee` for a complete example using separate servers for Socket.IO and Express. The Socket.IO and Express applications can run on the same host using Node.js clustering, on the same host but in different Node.js processes, or on different hosts.

## APP SETTINGS

You can use the following options with `@set`, `@enable` and `@disable`.

Any of Express' options are available as well.

### `minify`

Uses uglify-js to minify the outputs of `/zappa/simple.js`, `/zappa/zappa.js`, `@client`, `@shared`, `@coffee`, `@js`.

### `x-powered-by`

Unless disabled, ZappaJS adds a `X-Powered-By` header in HTTP responses.

### `zappa_prefix`

Normally a prefix of `/zappa` is used for all Zappa-specific URIs. This settings allows you to specify a different path.

### `zappa_channel`

The name of Zappa's local channel, used between ZappaJS and ZappaJS-client. Default to `__local`.

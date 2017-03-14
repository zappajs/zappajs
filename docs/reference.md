---
layout: default
title: Core API Reference (v6.1)
---

# {{page.title}}

## Core vs Plugins

This is the documentation for ZappaJS' core API.

You might also be interested by

- the [client plugin](https://github.com/zappajs/zappajs-plugin-client), to embed client-side code in your Zappa application;
- the [CSS plugin](https://github.com/zappajs/zappajs-plugin-css), to serve CSS using your preferred CSS engine.

For client-side code, you should review [zappajs-client](https://github.com/zappajs/zappajs-client). This module is especially designed to ensure you can easily share session data between multiple Express and Socket.io instances, even on different servers.

## Associating Express and Socket.io sessions

ZappaJS allows you to easily share session data between Express and Socket.io.

The Socket.IO and Express applications can run on the same host using Node.js clustering, on the same host but in different Node.js processes, or on different hosts. Express and Socket.io can thus be scaled independently.

The association is done automatically for the default, local Express session and local Socket.IO server by [`zappajs-client`](https://github.com/zappajs/zappajs-client#usage). `zappajs-client` also allows you to specify a separate Socket.IO server, in which case it will automatically associate that server's session with the current ExpressJS session.

Note: You must use Zappa's `@use session:....` instead of directly calling `@use 'express-session'` if you plan to use this feature.

See `examples/share_*.coffee` for a complete example that shows how to use separate servers for Socket.IO and Express.

## References

For a list of standard middleware, see [the Connect documentation](https://github.com/senchalabs/connect#middleware).

A lot of Zappa methods are shortcuts or extensions of the [Express API](http://expressjs.com/4x/api.html).

## Debug

Zappa uses [`debug`](https://github.com/visionmedia/debug) with the `zappajs` name.

## MODULE EXPORTS

`require 'zappajs'` returns a function with the following attributes:

### zappa.app

    zappa.app function [, options]

    zappa.app [options ,] function

Builds an app with express/socket.io, based on the function you provided.

The function you provided will be called with the value of `this`/`@` set to an object with all the attributes described in the [**root scope**](#root-scope) section.

You might also provide an object containing options. The following options are available:

* `io`: options for the Socket.IO server. Set to `false` to disable Socket.IO. Defaults to `{}`.
* `https`: object containing [options for HTTPS](http://nodejs.org/api/tls.html#tls_tls_createserver_options_secureconnectionlistener). Generally `key` and `cert` are all you need:

        # Start a HTTPS server on port 443
        require('zappajs') 443, https:{ key: ... , cert: ... }, ->
          @get '/': 'hi'

The following options are available, but using them will void your warranty:

* `express`: override the default express module with this one. Defaults to `require('express')`.
* `socketio`: override the default Socket.io module with this one. Defaults to `require('socket.io')`.
* `http_module`: override the default http/https module used to create a server with this one. Defaults to `require('https')` if `options.https` is present, to `require('http')` otherwise.
* `server`: override the default HTTP or HTTPS server normally created by ZappaJS with this one.
* `io_handler`: override the default Socket.io server normally created by ZappaJS with this one.
* `seem`: override the default async module (for example if you'd rather use [`co` v4](https://www.npmjs.com/package/co) than [`seem`](https://www.npmjs.com/package/seem)).

Returns the [**root scope**](#root-scope).

### zappa.run

    zappa.run [port,] [host,] [options,] function

or, simply:

    zappa [port,] [host,] [options,] function

Same as `zappa.app`, but calls `server.listen` for you. To know when the server is ready, wait for the `listening` event on the `server` field of the [**root scope**](#root-scope):

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

You can also pass the parameters in the `options` object; they are described in the previous section, with the addition of the following options:

* `port`: the port number for the web server.
* `host`: the hostname or IP address for the web server.
* `path`: IPC path; if present, ZappaJS will start an [IPC server](https://nodejs.org/api/net.html#net_server_listen_path_backlog_callback) instead of a TCP/IP server.
* `ready`: this function is called once the server is ready to accept requests.
* `server`: if the `server` option is set to the string `cluster`, ZappaJS will use `throng` to start and manage a Node.js cluster. In this case the function will not return anything useful; use the `ready` option to handle server startup.

The default port and host may also be specified as part of the environment variables, using `ZAPPA_PORT` and `ZAPPA_HOST`, respectively.

### zappa.version

Version of zappa running.

## ROOT SCOPE

The function you pass to `zappa.app` or `zappa.run` will be called with `this`/`@` set to an object with the following attributes:

### @get, @post, @put, @delete, @head, @patch, .., @all

    @get '/path': handler

    @get '/path', middleware, ..., handler

Define handlers for HTTP requests.

Shortcuts to express' `app[verb]`. Params will just be passed forward unmodified (except for the handler functions, which will be re-scoped), unless a single object is passed. In which case, each key in the object will be a route path, and the value its respective handler. The handler can be a function or a string. In the latter case, the handler passed to express will be a function that only calls `res.send` with this string.

The handler functions will have access to all variables described in the [**request handlers scope**](#request-handler-scope) section. The middleware functions can also get access to those variables, but for performance reasons this is not enabled by default, use `@wrap` to give them access.

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

Assuming `user_db.get` and `group_db.get` are async and return Promises:

    @get '/user/:name', ->
      user = yield user_db.get @params.name
      group = yield group_db.get user.group
      @json {user,group}

Example using a Route Middleware:

    load_user = @wrap ->
      user = users[@params.id]
      if user
        @locals.user = user
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

The handler functions will have access to all variables described in the [**socket handler scope**](#socket-handler-scope) section. They won't have access to their parent scope. To make variables available from the parent scope to these handlers, use [`@helper`](#helper).

If a handler returns a generator, that generator will be assumed to be an async function and will be passed through `seem` to yield a result.

Some standard events are generated automatically by Socket.IO: `connection`, `disconnect`.

    @on event, middleware, ..., handler

    @on event, [middleware, ...], handler

    @on event: [middleware,...,handler]

These form are all equivalent and allow per-event middleware.

Socket.IO middleware has access to

### @helper

Helpers content is made available to both the [request handler](#request-handler-scope) and [socket handler](#socket-handler-scope) scopes.

When you create a helper with the name `name`, the value of the helper is available as `@name` in the [request handler scope](#request-handler-scope) and the [socket handler scope](#socket-handler-scope).

#### @helper (data)

    @helper name: data

The helper will provide the associated data.

#### @helper (function)

    @helper name: function

The function will be available to both the [request handler](#request-handler-scope) and [socket handler](#socket-handler-scope) scopes. It will have access to the same context (scope) as whatever called it. Ex.:

    @get '/': ->
      @sum 5, 7

    @on connection: ->
      @sum 26, 18

    @helper sum: (a, b) ->
                            # Values when called from `@get` vs `@on`
      console.log a         # 5 vs 26
      console.log @request  # available vs undefined
      console.log @join     # undefined vs available

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
      ul ->
        for item in items
          li item

To use other engines, just use express' mechanisms:

    @render 'index.pug'

Or:

    @set 'view engine': 'pug'

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

### `@io_use`

Inject middleware for all Socket.io messages.

ZappaJS provides one internal middleware.

#### `@io_use session: ...`

Used to provide Zappa with the session-store (see the section on `session` for the Zappa Express middleware).
Use it when you run a Socket.IO-only version of your application, and the Express session is not needed.
Otherwise use `@use session: ...` as usual to support both Express and Socket.io.

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

Install a plugin in your ZappaJS application.

Known plugins:
- [Client Plugin](https://github.com/zappajs/zappajs-plugin-client), adds `@client`, `@browser`, `@isomorph`.
- [CSS Plugin](https://github.com/zappajs/zappajs-plugin-css), adds a function named after the CSS rendering library's name. For example `@with css:'stylus'` will provide `@stylus`.

#### @with function-or-module

Install the function/module as plugin.

#### @with 'name'

Install the module `zappajs-plugin-#{name}` as plugin.

The plugin package must be available.

For example,

    @with 'client'

is a shortcut for

    @with require 'zappajs-plugin-client'

which means the [Client Plugin](https://github.com/zappajs/zappajs-plugin-client) must be present in your application.

Use `npm install --save zappajs-plugin-client` to add the `client` plugin to your application.

#### @with name: arguments

Similar to `@with 'name'`; the arguments are passed to the module's main export function.

### @zappa

The same object that is exported when you `require 'zappajs'`.

### @express

The object returned by `require 'express'`, or the `options.express` field of the options provided to zappa.

### @session

The object returned by `require 'express-session'`.

### @server

The HTTPS or HTTP server created by zappa.

Normally created using `options.http_module.createServer()`. Since `options.http_module` defaults to `require('https')` if `options.https` is present, to `require('http')`, the server is enabled by default and does not require configuration.

Uses `options.server` if present.

### @io

The Socket.io object returned created by zappa. Normally created using `options.socketio(@server,options.io)`. Since `options.socketio` defaults to `require('socket.io')` and `options.io` defaults to `{}`, Socket.io is enabled by default and does not require configuration.

Uses `options.io_handler` if present, unless `options.io` is `false`.

### @app

The object returned by `express()`.

[Express Application API](http://expressjs.com/en/4x/api.html#app)

### @teacup

A shortcut to the [`teacup`](https://github.com/goodeggs/teacup#readme) module.

### @id

A unique UUID generated for this zappa instance.

## REQUEST HANDLER SCOPE

The function you pass to `@get`, `@post`, etc., will be called with `this`/`@` set to an object with the following attributes.
These attributes are also available to functions passed to `@param`, unless specified otherwise.
These attributes are also available to `@wrap`ped middleware functions, unless specified otherwise.

### @response

Directly from express.

Shortcut: `@res` is a synonym for `@response`.

[Express Response API](http://expressjs.com/en/4x/api.html#res)

### @request

Directly from express.

Shortcut: `@req` is a synonym for `@request`.

[Express Request API](http://expressjs.com/en/4x/api.html#req)

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

Send a Socket.IO message to the client's socket, assuming the Express and the Socket.io sessions [have been associated](#associating-express-and-socketio-sessions).

    @emit 'message', data

    @emit 'message', data, (ack_data) ->
      console.log 'Client acknowledged with data'

If the `ack` handler returns a generator, that generator will be assumed to be an async function and will be passed through `seem` to yield a result.

### `@broadcast_to`

    @broadcast_to room, msg

Shortcut to `@io.in(room).emit`.

Broadcast to a room.

### @io

The object returned by `require('socket.io').listen`. Same as in the root scope.

### @id

The `socket.id` of the client. Only available after the express and the socket.io sessions have been associated.

### @app

The object returned by `express()`.

[Express Application API](http://expressjs.com/en/4x/api.html#app)

### @settings

Shortcut to `@app.settings`.

## SOCKET HANDLER SCOPE

The function you pass to `@on` will be called with `this`/`@` set to an object with the following attributes:

### @socket

Directly from socket.io.

### @data, @body, @req.body

Directly from socket.io. The data sent by the client in the message.

### @ack

Directly from socket.io. Used to provide acknowledgement of messages sent by `@emit` on the client.

    @on start: ->
      console.log @data # 'now'
      @ack 'Got it!'

    @with `client`
    @browser '/index.js', ->
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

Shortcut to `@io.in(room).emit`.

Broadcast to a room.

### @session, @req.session

If available, the Express session object associated with the Socket.io socket.

The session object is only available _after_ the Socket.IO socket has been associated with the Express session; it is especially *not* available inside `@on connection` since at that time the client hasn't had an opportunity to process the association.

The association is done automatically for the default, local Express session and local Socket.IO server by [`zappajs-client`](https://github.com/zappajs/zappajs-client#usage). `zappajs-client` also allows you to specify a separate Socket.IO server, in which case it will automatically associate that server's session with the current ExpressJS session.

Note: You must use Zappa's `@use session:....` instead of directly calling `@use 'express-session'` if you plan to use this feature.

See `examples/share_*.coffee` for a complete example using separate servers for Socket.IO and Express. The Socket.IO and Express applications can run on the same host using Node.js clustering, on the same host but in different Node.js processes, or on different hosts.

`@req.session` is provided for compatibility with Express middleware.

### @locals, @res.locals, @response.locals

Object shared on a given socket.io handler, available to middlewares and the final event handler.

### @req, @request

Provided for compatibility with Express middleware.

#### @req.body

The data sent by the client in the message.

#### @req.session

The session object associated with the socket, see `@session`.

### @res, @response

Provided for compatibility with Express middleware.

#### @res.locals, @response.locals

Used to pass values between middlewares on the same event handler.

### @io

The object returned by `require('socket.io').listen`. Same as in the root scope.

### @app

The object returned by `express()`.

[Express Application API](http://expressjs.com/en/4x/api.html#app)

### @settings

Shortcut to `@app.settings`.

## APP SETTINGS

You can use the following options with `@set`, `@enable` and `@disable`.

Any of Express' options are available. The following settings are specific to ZappaJS.

### `minify`

Uses uglify-js to minify the outputs of `/zappa/simple.js`, `/zappa/zappa.js`, `@client`, `@shared`, `@coffee`, `@js`.

### `x-powered-by`

Unless disabled, ZappaJS adds a `X-Powered-By` header in HTTP responses.

### `zappa_prefix`

Normally a prefix of `/zappa` is used for all Zappa-specific URIs. This settings allows you to specify a different path.

### `zappa_channel`

The name of Zappa's local channel, used between ZappaJS and ZappaJS-client. Defaults to `__local`.

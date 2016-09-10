Zappa
=====

**Zappa** is a [CoffeeScript](http://coffeescript.org) DSL-ish interface for building web apps on the [node.js](http://nodejs.org) runtime, integrating [express](http://expressjs.com), [socket.io](http://socket.io) and other best-of-breed libraries.

    pkg = require '../package'
    zappa = version: pkg.version

    debug = (require 'debug') pkg.name
    fs = require 'fs'
    path = require 'path'
    util = require 'util'
    uuid = require 'node-uuid'
    methods = require 'methods'
    invariate = require 'invariate'

    session = require 'express-session'
    io_session = require './io-session'
    zappa_settings = require './settings'

Soft dependencies:

    uglify = null
    coffee_css = null

CoffeeScript-generated JavaScript may contain anyone of these; when we "rewrite" a function (see below) though, it loses access to its parent scope, and consequently to any helpers it might need. So we need to reintroduce these helpers manually inside any "rewritten" function.
This list is taken from coffeescript's `src/nodes.coffee` UTILITIES.

    coffeescript_helpers = require 'coffeescript-helpers'

    minify = (js) ->
      uglify ?= require 'uglify-js'
      result = uglify.minify js, fromString:true
      result.code

Flatten array recursively (copied from Express's utils.js)

    flatten = (arr, ret) ->
      ret ?= []
      for o in arr
        if Array.isArray o
          flatten o, ret
        else
          ret.push o
      ret

Zappa Application
=================

Takes in a function and builds express/socket.io apps based on the rules contained in it.

    zappa.app = ->
      for a in arguments
        switch typeof a
          when 'function'
            func = a
          when 'object'
            options = a

      options ?= {}

      express = options.express ? require 'express'

      seem = options.seem ? require 'seem'

      seemify = (require './seemify') seem

      context = {id: uuid.v4(), zappa, express, session}

      root = path.dirname module.parent.filename

Storage for user-provided stuff:

- Handlers (callbacks) for Socket.IO;

      ws_handlers = {}

- Helper functions.

      helpers = {}

The application itself is ExpressJS'.

      app = context.app = express()

Use the `https` options to create a HTTP web server, create a plain HTTP server otherwise.

      if options.https?
        context.server = require('https').createServer options.https, app
      else
        context.server = require('http').createServer app

Set `options.io` to `false` to disable socket.io.
Set `options.io` to socket.io's parameters otherwise (optional).
Default is to enable Socket.IO with its default options.

      io = null
      if options.io isnt false
        socketio = options.socketio ? require 'socket.io'
        io = context.io = socketio context.server, options.io ? {}

ZappaView
=========

      views = context.views = {}

Zappa View is used to inject views declared inside the Zappa context into Express (without writing them to the filesystem, etc.).

This is our own version of Express' original `lib/view.js`.

      class ZappaView
        constructor: (name,options = {}) ->
          @root = options.root ? ''
          engines = options.engines
          defaultEngine = options.defaultEngine
          @ext = path.extname name
          if not @ext and not defaultEngine
            throw new Error 'No default engine was specified and no extensions was provided.'
          if not @ext
            @ext = if defaultEngine[0] isnt '.' then ".#{defaultEngine}" else defaultEngine
            name += @ext
          [@path,@proto] = @lookup name
          if @proto?
            if @proto
              @engine = engines["#{@ext} zappa"] ?= require(@ext.slice 1).render
            else
              @engine = engines[@ext] ?= require(@ext.slice 1).__express
          @path

Lookup
------

First look inside our internal set of views, then use the filesystem.
Return `path,proto` where `proto` indicates whether the document is internal or filesystem.

        lookup: (p) ->
          exists = (p) ->
            if views[p]?
              return [p,true]
            if fs.existsSync p
              return [p,false]
            null

          exists( path.resolve @root, p ) ? exists( path.join path.dirname(p), path.basename(p,@ext), "index.#{@ext}" ) ? [null,null]

Render
------

Try to render the internal view or the filesystem view based on the `proto` flag.

        render: (options,fn) ->
          if @proto
            e = null
            try
              # FIXME: pass parameters as per Express2
              r = @engine views[@path], options, @path
            catch error
              e = "Engine .render for #{@ext} failed: #{error}"
            fn e, r
          else
            @engine @path, options, fn

Zappa's default settings
========================

      app.set 'view', ZappaView
      app.set 'view engine', 'coffee'

      teacup = require 'teacup'
      teacup_express = require 'teacup/lib/express'

Render `.coffee` files using Teacup.

      app.engine 'coffee', teacup_express.renderFile

Render our internal views using Teacup as well.

      app.engine 'coffee zappa', (template,options) -> (teacup.renderable template).call options, options

Provide `@teacup`.

      context.teacup = teacup

      app.set 'views', path.join(root, '/views')

Location of zappa-specific URIs.

      app.set 'zappa_prefix', '/zappa'

`apply_helpers`
===============

      apply_helpers = (ctx) ->
        for name, helper of helpers
          do (name, helper) ->
            if typeof helper is 'function'
              ctx[name] = ->
                seemify helper, ctx, arguments
            else
              ctx[name] = helper
            return
        ctx

route
=====

Register a route with express.

      route = (require './route') {context,apply_helpers,seemify}

Middleware handling
===================

Turn a function such as `route` or `receive` into a middleware-supporting function.

      middlewarify = (handler,verb = null) ->
        (args...) ->
          arity = args.length

Multiple arguments: path, middleware..., handler

          if arity > 1
            handler
              verb: verb
              path: args[0]
              middleware: flatten args[1...arity-1]
              handler: args[arity-1]

Single argument: multiple routes in an object.

          else
            for k, v of args[0]

For each individual entry, if the value is an array, its content must be `middleware..., handler`.

              if v instanceof Array
                handler
                  verb: verb
                  path: k
                  middleware: flatten v[0...v.length-1]
                  handler: v[v.length-1]

Otherwise, the value is simply the handler.

              else
                handler
                  verb: verb
                  path: k
                  handler: v
            return

Verbs (aka HTTP methods)
========================

      for verb in [methods...,'all']
        do (verb) ->
          context[verb] = middlewarify route, verb

.route
======

      context.route = (p) ->
        app.route p

.coffee
=======

      context.coffee = invariate (k,v) ->
        js = coffeescript_helpers.p_exec v
        js = minify(js) if app.settings['minify']
        route verb: 'get', path: k, handler: js, type: 'js'
        return

.js
===

      context.js = invariate (k,v) ->
        js = String(v)
        js = minify(js) if app.settings['minify']
        route verb: 'get', path: k, handler: js, type: 'js'
        return

.css
====

      context.css = invariate (k,v) ->
        if typeof v is 'object'
          coffee_css ?= require 'coffee-css'
          css = coffee_css.compile v
        else
          css = String(v)
        route verb: 'get', path: k, handler: css, type: 'css'
        return

.helper
=======

      context.helper = invariate (k,v) ->
        helpers[k] = v
        return

.on
===


A ws_handler has signature `(ctx) ->` (they are only used internally).
A middleware has signature `(ctx,res,next) ->` (to be compatible with existing middleware).
A final handler has signature `(data,ack) ->` (to be compatible with existing socket handlers).

      receive = (r) ->

The final handler is wrapped.

        handler = (ctx) ->
          seemify r.handler, ctx, [ctx.data, ctx.ack]

Message-specific and global middlewares are applied.

Translate a `middleware` and a `ws_handler` into a single `ws_handler`.

        functor = (m,next) ->
          (ctx) ->
            m ctx, ctx.res, (error) ->
              if error?
                throw error
              else
                next ctx

        if r.middleware?
          for m in r.middleware.reverse()
            handler = functor m, handler
        if ws_use?
          for m in ws_use.reverse()
            handler = functor m, handler

The socket handler is created.

        (ws_handlers[r.path] ?= []).push handler

      context.on = middlewarify receive

      ws_use = []

      context.io_use = ->
        zappa_middleware =
          session: (options) ->
            context.session_store = options.store

        use = (name, arg = null) ->
          if zappa_middleware[name]
            ws_use.push zappa_middleware[name](arg)
          else
            ws_use.push (require name)(arg)

        for a in arguments
          switch typeof a
            when 'function'
              ws_use.push a
            when 'string'
              use a
            when 'object'
              use k, v for k, v of a
        return

.view
=====

Define an internal view. Since the lookup will use a full pathname, make sure an extension is provided.

      context.view = invariate (k,v) ->
        ext = path.extname k
        p = path.join app.get('views'), k
        if not ext
          p += '.' + app.get('view engine')
        views[p] = v
        return

.engine
=======

      context.engine = invariate (k,v) ->
        app.engine k, v
        return

.set
====

      context.set = invariate (k,v) ->
        app.set k, v
        return

.enable
=======

      context.enable = ->
        app.enable i for i in arguments
        return

.disable
========

      context.disable = ->
        app.disable i for i in arguments
        return

.wrap
=====

Wrap Zappa-oriented middlewares so that they can be ran as regular Express middleware.

      context.wrap = (f) ->
        (req,res,next) ->

This is the context available to Zappa middleware.

          ctx =
            app: app
            io: io
            settings: app.settings
            locals: res.locals
            session: req.session

# Express-only

            request: req
            req: req
            query: req.query
            params: req.params
            body: req.body
            response: res
            res: res
            next: next

            send: -> res.send.apply res, arguments
            json: -> res.json.apply res, arguments
            jsonp: -> res.jsonp.apply res, arguments
            redirect: -> res.redirect.apply res, arguments
            format: -> res.format.apply res, arguments

# IO-only

            socket: req.socket
            client: req.client
            data: req.data
            ack: req.ack

            join: -> req.join.apply req, arguments
            leave: -> req.leave.apply req, arguments
            emit: -> req.emit.apply req, arguments
            broadcast: -> req.broadcast.apply req, arguments
            broadcast_to: -> req.broadcast_to.apply req, arguments

          apply_helpers ctx
          seemify f, ctx, [req, res, next]

.use
====

      context.use = ->

Zappa middleware available as `@use 'zappa'`, `@use session:options`.

        zappa_middleware =
          static: (options) ->
            if typeof options is 'string'
              options = path: options
            options ?= {}
            p = options.path ? path.join(root, '/public')
            delete options.path
            express.static(p,options)
          session: (options) ->
            context.session_store = options.store
            session options

        use = (name, arg = null) ->
          if zappa_middleware[name]
            app.use zappa_middleware[name](arg)
          else if typeof express[name] is 'function'
            app.use express[name](arg)
          else
            app.use (require name)(arg)

        for a in arguments
          switch typeof a
            when 'function' then app.use a
            when 'string' then use a
            when 'object'
              if a.stack? or a.route? or a.handle?
                app.use a
              else
                use k, v for k, v of a
        return

.settings
=========

      context.settings = app.settings

.locals
=======

      context.locals = app.locals

.include
========

      context.include = (p,args...) ->
        sub = if typeof p is 'string' then require path.join(root, p) else p
        sub.include.apply context, args

.param
======

      build_param = (callback) ->
        (req,res,next,p) ->

Context available to `param` functions.

          ctx =
            app: app
            io: io
            settings: app.settings
            locals: res.locals
            request: req
            req: req
            query: req.query
            params: req.params
            body: req.body
            session: req.session
            response: res
            res: res
            next: next
            param: p
          apply_helpers ctx
          callback.call ctx, req, res, next, p

      context.param = invariate (k,v) ->
        app.param k, build_param v
        return

Socket.IO
=========

Zappa local channel (the default channel used for @emit inside Zappa's own @get etc.).

      app.set 'zappa_channel', '__local'

Register socket.io handlers.

      io?.sockets.on 'connection', (socket,ack) ->
        c = {}

        build_ctx = (o) ->

Context available inside the Socket.IO `on` functions.

          ctx =
            app: app
            io: io
            settings: app.settings
            locals: app.locals
            socket: socket
            id: socket.id
            client: c
            join: (room) ->
              socket.join room
            leave: (room) ->
              socket.leave room
            emit: invariate.acked (k,v,ack) ->
              socket.emit.call socket, k, v, (ack_data) ->
                ctx = build_ctx
                  event: k
                  data: ack_data
                seemify ack, ctx, arguments
              return
            broadcast: invariate (k,v) ->
              broadcast = socket.broadcast
              broadcast.emit.call broadcast, k, v
              return
            broadcast_to: (room, args...) ->
              room = io.to room
              broadcast = invariate (k,v) ->
                room.emit.call room, k, v
              broadcast args...
              return

          apply_helpers ctx
          if o?
            ctx[k] = v for own k,v of o
          ctx

Wrap event handlers

        wrap_handler = (event,handler) ->
          (data,ack) ->

Provide req.body just like a body parser middleware would.

            req =
              body: data

Provide res.locals just like Express does.

            res =
              locals: {}

Provide a socket-handler context.

            ctx = build_ctx
              event: event
              data: data
              body: data
              ack: ack
              res: res
              response: res
              req: req
              request: req

            handler ctx, res

        for event, handlers of ws_handlers when event isnt 'connection'
          do (event,handlers) ->
            for handler in handlers
              socket.on event, wrap_handler event, handler

        debug 'Socket.IO ready'

Trigger any handler for the `connection` event that the app might have installed.

        handlers = ws_handlers.connection

        if handlers?
          for handler in handlers
            (wrap_handler 'connection', handler) null, ack
        return

.with
=====

Applies a plugin to the current context.

      context.with = invariate (k,v) ->
        ctx = {context,route,root,minify,require}
        if typeof k is 'string'
          k = require "zappajs-plugin-#{k}"
        k.call ctx, v

Go!
===

      func.apply context

Express-side API to bind with Socket.IO
=======================================

      io_session {context}
      zappa_settings {context}

      context

`zappa.run [host,] [port,] [{options},] root_function`
======================================================

Takes a function and runs it as a zappa app. Optionally accepts a port number, and/or a hostname (any order). The hostname must be a string, and the port number must be castable as a number.

    zappa.run = ->
      host = process.env.ZAPPA_HOST ? null
      port = process.env.ZAPPA_PORT ? 3000
      ipc_path = process.env.ZAPPA_PATH ? null
      root_function = null
      options = {}

      for a in arguments
        switch typeof a
          when 'string'
            if isNaN( (Number) a ) then host = a
            else port = (Number) a
          when 'number' then port = a
          when 'function' then root_function = a
          when 'object'
            for k, v of a
              switch k
                when 'host' then host = v
                when 'port' then port = v
                when 'path' then ipc_path = v
                else options[k] = v

      zapp = zappa.app(root_function,options)
      {server,app} = zapp

      server.on 'listening', ->
        addr = server.address()
        channel = if typeof addr is 'string' then addr else addr.address + ':' + addr.port
        debug """
          Express server listening on #{channel} in #{app.settings.env} mode.
          Zappa #{zappa.version} orchestrating the show.

        """

      switch
        when ipc_path
          server.listen ipc_path
        when host
          server.listen port, host
        else
          server.listen port

The value returned by `Zappa.run` (aka `Zappa`) is the global context.

      zapp

    module.exports = zappa.run
    module.exports.run = zappa.run
    module.exports.app = zappa.app
    module.exports.version = zappa.version

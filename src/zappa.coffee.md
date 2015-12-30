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
    seem = require 'seem'

    session = require 'express-session'

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

Provide `@teacup` and `@seem`.

      context.teacup = teacup
      context.seem = seem

      app.set 'views', path.join(root, '/views')

Location of zappa-specific URIs.

      app.set 'zappa_prefix', '/zappa'

Verbs (aka HTTP methods)
========================

      for verb in [methods...,'all']
        do (verb) ->
          context[verb] = (args...) ->
            arity = args.length

Multiple arguments: path, middleware..., handler

            if arity > 1
              route
                verb: verb
                path: args[0]
                middleware: flatten args[1...arity-1]
                handler: args[arity-1]

Single argument: multiple routes in an object.

            else
              for k, v of arguments[0]

For each individual entry, if the value is an array, its content must be `middleware..., handler`.

                if v instanceof Array
                  route
                    verb: verb
                    path: k
                    middleware: flatten v[0...v.length-1]
                    handler: v[v.length-1]

Otherwise, the value is simply the handler.

                else
                  route verb: verb, path: k, handler: v
            return

.client
=======

FIXME: either remove, or use browserify to run within zappajs-client.

      context.client = invariate (k,v) ->
        js = ";zappa.run(#{v});"
        js = minify(js) if app.settings['minify']
        route verb: 'get', path: k, handler: js, type: 'js'
        return

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

.with
=====

      zappa_with =
        css: (modules) ->
          if typeof modules is 'string'
            modules = [modules]
          for name in modules
            module = require(name)
            context[name] = invariate (k,v) ->
              module.render v, filename: k, (err, css) ->
                throw err if err
                css = css.css if css.css? and typeof css.css is 'string' # less
                route verb: 'get', path: k, handler: css, type: 'css'
              return
          return

      context.with = invariate (k,v) ->
        if zappa_with[k]
          zappa_with[k] v

.helper
=======

      context.helper = invariate (k,v) ->
        helpers[k] = v
        return

.on
===

      context.on = invariate (k,v) ->
        ws_handlers[k] = v
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
            send: -> res.send.apply res, arguments
            json: -> res.json.apply res, arguments
            jsonp: -> res.jsonp.apply res, arguments
            redirect: -> res.redirect.apply res, arguments
            format: -> res.format.apply res, arguments

          apply_helpers ctx
          f.call ctx, req, res, next

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

.local
======

      context.locals = app.locals

.shared
=======

FIXME: same as .client, browserify or remove

      context.shared = invariate (k,v) ->
        js = ";zappa.run(#{v});"
        js = minify(js) if app.settings['minify']
        route verb: 'get', path: k, handler: js, type: 'js'
        v.apply context
        return

.include
========

      context.include = (p,args...) ->
        sub = if typeof p is 'string' then require path.join(root, p) else p
        sub.include.apply context, args

`apply_helpers`
===============

      apply_helpers = (ctx) ->
        for name, helper of helpers
          do (name, helper) ->
            if typeof helper is 'function'
              ctx[name] = ->
                helper.apply ctx, arguments
            else
              ctx[name] = helper
            return
        ctx

.param
======

      build_param = (callback) ->
        (req,res,next,p) ->

Context available to `param` functions.

          ctx =
            app: app
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

route
=====

Register a route with express.

      route = (r) ->
        r.middleware ?= []

        if typeof r.handler is 'string'
          app[r.verb] r.path, r.middleware, (req, res) ->
            res.type r.type if r.type?
            res.send r.handler
            return
        else if r.handler.call?
          app[r.verb] r.path, r.middleware, (req, res, next) ->

Context available inside the `get`, ... handlers.

            ctx =
              app: app
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
              send: -> res.send.apply res, arguments
              json: -> res.json.apply res, arguments
              jsonp: -> res.jsonp.apply res, arguments
              redirect: -> res.redirect.apply res, arguments
              format: -> res.format.apply res, arguments
              render: ->
                if typeof arguments[0] isnt 'object'
                  render.apply @, arguments
                else
                  for k, v of arguments[0]
                    render.apply @, [k, v]
                return
              emit: invariate.acked (k,v,ack) ->
                socket_id = req.session?.__socket?[app.settings.zappa_channel]?.id
                if socket_id?
                  room = io.sockets.in socket_id
                  room.emit.call room, k, v, ack
                return

            render = (name,opts = {},fn) ->

              report = fn ? (err,html) ->
                if err
                  next err
                else
                  res.send html

              # Make sure the second arg is an object.
              if typeof opts is 'function'
                fn = opts
                opts = {}

              res.render.call res, name, opts, report

            apply_helpers ctx

            if app.settings['x-powered-by']
              res.setHeader 'X-Powered-By', "Zappa #{zappa.version}"

            result = r.handler.call ctx, req, res, next
            if typeof result?.then is 'function'
              result.then (result) ->
                res.type(r.type) if r.type?
                if typeof result is 'string' then res.send result
                else return result
              , next
              return

            res.type(r.type) if r.type?
            if typeof result is 'string' then res.send result
            else return result

        else
          throw new Error "ZappaJS invalid handler of type #{typeof r.handler}: #{util.inspect r.handler}"

Socket.IO
=========

Zappa local channel (the default channel used for @emit inside Zappa's own @get etc.

      app.set 'zappa_channel', '__local'

Register socket.io handlers.

      io?.sockets.on 'connection', (socket) ->
        c = {}
        session_id = null

        build_ctx = ->

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
              socket.emit.call socket, k, v, ack
              return
            broadcast: invariate (k,v) ->
              broadcast = socket.broadcast
              broadcast.emit.call broadcast, k, v
              return
            broadcast_to: (room, args...) ->
              room = io.sockets.in room
              broadcast = invariate (k,v) ->
                room.emit.call room, k, v
              broadcast args...
              return

          apply_helpers ctx
          ctx

Wrap the handler for `connection`

        ctx = build_ctx()
        ws_handlers.connection.apply(ctx) if ws_handlers.connection?

Wrap the handler for `disconnect`

        socket.on 'disconnect', ->
          ctx = build_ctx()
          ws_handlers.disconnect.apply(ctx) if ws_handlers.disconnect?

The special event `__zappa_settings` is used by the client to request that the current application settings be sent back.

        socket.on '__zappa_settings', (data,ack) ->
          unless ack?
            debug 'Client did not request `ack` for __zappa_settings'
            return
          ack app.settings

Bind with Express
-----------------

The special event `__zappa_key` is used by the client to notify us of the key provided by Express.

        socket.on '__zappa_key', ({key},ack) ->
          unless ack?
            debug 'Client did not request `ack` for __zappa_key'
            return

          unless context.session_store?
            debug 'Missing session-store.'
            ack error:'Missing session-store.'
          unless key?
            debug 'Missing key.'
            ack error:'Missing key.'
            return

Retrieve the data record associated with the key.

          context.session_store.get key, (err,data) ->
            if err?
              debug 'session_store.get #{key}: #{err}'
              ack error:err.toString()
              return
            if not data?
              debug 'session_store.get #{key}: Missing data'
              ack error:'Missing data'
              return

Bind the session.id so that the handlers can access the session.

            session_id = data.id
            ack {key}

        get_session = (next) ->
          unless context.session_store? and session_id?
            debug 'get_session() not ready'
            next null
            return

Retrieve the session data stored by Express

          context.session_store.get session_id, (error,data) ->
            if error
              next null
              return
            next data

Wrap all other (event) handlers

        for name, h of ws_handlers
          do (name, h) ->
            if name isnt 'connection' and name isnt 'disconnect'
              socket.on name, (data, ack) ->
                ctx = build_ctx()
                ctx.event = name
                ctx.data = data
                ctx.ack = ack
                get_session (session) ->
                  ctx.session = session
                  h.call ctx, data, ack
                  session?.save()
            return

        return

Go!
===

      func.apply context

Express-side API to bind with Socket.IO
=======================================

      do ->

API used by the client (e.g. `zappajs-client`) to create an Express-side key that will be used to bind Express and Socket.io sessions.

        zappa_prefix = app.settings.zappa_prefix
        context.get zappa_prefix+'/socket/:channel_name/:socket_id', ->
          if not context.session_store?
            debug 'Missing session-store.'
            @res.status 500
            @json error:'No session-store.'
            return

          if not @session?
            debug 'Missing session.'
            @res.status 400
            @json error:'No session'
            return

          channel_name = @params.channel_name
          socket_id = @params.socket_id

Use memoized socket data if available.

          @session.__socket ?= {}

          if @session.__socket[channel_name]?
            @json
              key: @session.__socket[channel_name].key
            return

Create a new socket session document
The `key` is used to hide the actual `@session.id` from the
client while allowing it to provide us with a pointer to the
session document using the key.

          key = uuid.v4() # used for socket 'authentication'

Update the store.

          data =
            id: @session.id   # local Express Session ID
            cookie: {}
          context.session_store.set key, data, (err) =>
            if err
              @json error: err.toString()
              return

Save the key and socket.id in the local Express session store.

            @session.__socket[channel_name] =
              id: socket_id
              key: key

Let the client know which key it should use on the Socket.IO side.

            @json
              key: key
          return

      context

`zappa.run [host,] [port,] [{options},] root_function`
======================================================

Takes a function and runs it as a zappa app. Optionally accepts a port number, and/or a hostname (any order). The hostname must be a string, and the port number must be castable as a number.

    zappa.run = ->
      host = process.env.ZAPPA_HOST ? null
      port = process.env.ZAPPA_PORT ? 3000
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
                else options[k] = v

      zapp = zappa.app(root_function,options)
      {server,app} = zapp

      server.on 'listening', ->
        addr = server.address()
        debug """
          Express server listening on #{addr.address}:#{addr.port} in #{app.settings.env} mode.
          Zappa #{zappa.version} orchestrating the show.

        """

      if host
        server.listen port, host
      else
        server.listen port

      zapp

    module.exports = zappa.run
    module.exports.run = zappa.run
    module.exports.app = zappa.app
    module.exports.version = zappa.version

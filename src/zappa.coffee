# **Zappa** is a [CoffeeScript](http://coffeescript.org) DSL-ish interface
# for building web apps on the [node.js](http://nodejs.org) runtime,
# integrating [express](http://expressjs.com), [socket.io](http://socket.io)
# and other best-of-breed libraries.

zappa = version: '1.0.1pre'

log = console.log
fs = require 'fs'
path = require 'path'
uuid = require 'node-uuid'
uglify = require 'uglify-js'
methods = require 'methods'

session = require 'express-session'
serveStatic = require 'serve-static'

vendor = (name) ->
  fs.readFileSync(path.join(__dirname,'..','vendor',name)).toString()

jquery = vendor 'jquery.js'
jquery_minified = vendor 'jquery.min.js'
sammy = vendor 'sammy.js'
sammy_minified = vendor 'sammy.min.js'
socketjs = vendor 'socket.io.js'

socketio_key = '__session'

# Soft dependencies:
jsdom = null
coffee_css = null

# CoffeeScript-generated JavaScript may contain anyone of these; when we
# "rewrite" a function (see below) though, it loses access to its parent scope,
# and consequently to any helpers it might need. So we need to reintroduce
# these helpers manually inside any "rewritten" function.
# This list is taken from coffeescript's `src/nodes.coffee` UTILITIES.
coffeescript_helpers = """
  var __slice = [].slice;
  var __hasProp = {}.hasOwnProperty;
  var __bind = function(fn, me){
    return function(){ return fn.apply(me, arguments); };
  };
  var __extends = function(child, parent) {
    for (var key in parent) {
      if (__hasProp.call(parent, key)) child[key] = parent[key];
    }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor();
    child.__super__ = parent.prototype;
    return child;
  };
  var __indexOf = [].indexOf || function(item) {
    for (var i = 0, l = this.length; i < l; i++) {
      if (i in this && this[i] === item) return i;
    } return -1; };
  var __modulo = function(a, b) { return (+a % (b = +b) + b) % b; };
""".replace /\n/g, ''

minify = (js) ->
  result = uglify.minify js, fromString:true
  result.code

# Flatten array recursively (copied from Express's utils.js)
flatten = (arr, ret) ->
  ret ?= []
  for o in arr
    if Array.isArray o
      flatten o, ret
    else
      ret.push o
  ret

# Takes in a function and builds express/socket.io apps based on the rules
# contained in it.
zappa.app = ->
  for a in arguments
    switch typeof a
      when 'function'
        func = a
      when 'object'
        options = a

  options ?= {}

  express = options.express ? require 'express'

  context = {id: uuid.v4(), zappa, express}

  root = path.dirname module.parent.filename

  # Storage for user-provided stuff.
  ws_handlers = {}
  helpers = {}
  postrenders = {}

  app = context.app = express()
  if options.https?
    context.server = require('https').createServer options.https, app
  else
    context.server = require('http').createServer app

  # Set options.io to false to disable socket.io.
  # Set options.io to socket.io's parameters otherwise (optional).
  # Set options.socketio if you need to use a different version of socket.io.
  io = null
  if options.io isnt false
    socketio = options.socketio ? require 'socket.io'
    io = context.io = socketio.listen context.server, options.io ? {}

  # Reference to the zappa client, the value will be set later.
  client = null
  client_bundled = null
  client_bundle_simple = null

  # Tracks if the zappa middleware is already mounted (`@use 'zappa'`).
  zappa_used = no

  views = context.views = {}

  # This is our own version of Express' original `lib/view.js`.
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

    lookup: (p) ->
      exists = (p) ->
        if views[p]?
          return [p,true]
        if fs.existsSync p
          return [p,false]
        null

      exists( path.resolve @root, p ) ? exists( path.join path.dirname(p), path.basename(p,@ext), "index.#{@ext}" ) ? [null,null]

    render: (options,fn) ->
      if @proto
        e = null
        try
          # FIXME: pass parameters as per Express2
          r = @engine views[@path], options
        catch error
          e = "Engine .render for #{@ext} failed: #{error}"
        fn e, r
      else
        @engine @path, options, fn

  # Zappa's default settings.
  app.set 'view', ZappaView
  app.set 'view engine', 'coffee'

  teacup = require 'teacup'
  teacup_express = require 'teacup/lib/express'

  app.engine 'coffee', teacup_express.renderFile
  app.engine 'coffee zappa', teacup.render
  context.teacup = teacup

  app.set 'views', path.join(root, '/views')

  # Location of zappa-specific URIs.
  app.set 'zappa_prefix', '/zappa'
  app.set 'zappa_channel', '__local'

  for verb in [methods...,'all']
    do (verb) ->
      context[verb] = (args...) ->
        arity = args.length
        if arity > 1
          route
            verb: verb
            path: args[0]
            middleware: flatten args[1...arity-1]
            handler: args[arity-1]
        else
          for k, v of arguments[0]
            # Apply middleware if value is array
            if v instanceof Array
              route
                verb: verb
                path: k
                middleware: flatten v[0...v.length-1]
                handler: v[v.length-1]

            else
              route verb: verb, path: k, handler: v
        return

  context.client = (obj) ->
    context.use 'zappa' unless zappa_used
    for k, v of obj
      js = ";zappa.run(#{v});"
      js = minify(js) if app.settings['minify']
      route verb: 'get', path: k, handler: js, contentType: 'js'
    return

  context.coffee = (obj) ->
    for k, v of obj
      js = ";#{coffeescript_helpers}(#{v})();"
      js = minify(js) if app.settings['minify']
      route verb: 'get', path: k, handler: js, contentType: 'js'
    return

  context.js = (obj) ->
    for k, v of obj
      js = String(v)
      js = minify(js) if app.settings['minify']
      route verb: 'get', path: k, handler: js, contentType: 'js'
    return

  context.css = (obj) ->
    for k, v of obj
      if typeof v is 'object'
        coffee_css ?= require 'coffee-css'
        css = coffee_css.compile v
      else
        css = String(v)
      route verb: 'get', path: k, handler: css, contentType: 'css'
    return

  context.with = (obj) ->
    zappa_with =
      css: (modules) ->
        if typeof modules is 'string'
          modules = [modules]
        for name in modules
          module = require(name)
          context[name] = (obj) ->
            for k, v of obj
              module.render v, filename: k, (err, css) ->
                throw err if err
                route verb: 'get', path: k, handler: css, contentType: 'css'
            return
        return

    for k,v of obj
      if zappa_with[k]
        zappa_with[k] v

  context.helper = (obj) ->
    for k, v of obj
      helpers[k] = v
    return

  context.postrender = (obj) ->
    jsdom = require 'jsdom'
    for k, v of obj
      postrenders[k] = v
    return

  context.on = (obj) ->
    for k, v of obj
      ws_handlers[k] = v
    return

  context.view = (obj) ->
    for k, v of obj
      ext = path.extname k
      p = path.join app.get('views'), k
      if not ext
        p += '.' + app.get('view engine')
      views[p] = v
    return

  context.engine = (obj) ->
    for k, v of obj
      app.engine k, v
    return

  context.set = (obj) ->
    for k, v of obj
      app.set k, v
    return

  context.enable = ->
    app.enable i for i in arguments
    return

  context.disable = ->
    app.disable i for i in arguments
    return

  wrap_middleware = (f) ->
    (req,res,next) ->
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

      apply_helpers ctx

      f.call ctx, req, res, next

  context.middleware = (f) ->
    # If magic middleware is enabled the function will get wrapped
    # by the caller; do not double-wrap it.
    if app.settings['magic middleware']
      f
    else
      wrap_middleware f

  use_middleware = (f) ->
    if app.settings['magic middleware']
      wrap_middleware f
    else
      f

  context.use = ->
    zappa_middleware =
      static: (options) ->
        if typeof options is 'string'
          options = path: options
        options ?= {}
        p = options.path ? path.join(root, '/public')
        delete options.path
        serveStatic(p,options)
      zappa: ->
        zappa_used = yes
        (req, res, next) ->
          send = (code) ->
            res.contentType 'js'
            res.send code
          if req.method.toUpperCase() isnt 'GET' then next()
          else
            zappa_prefix = app.settings['zappa_prefix']
            switch req.url
              when zappa_prefix+'/Zappa.js' then send client_bundled
              when zappa_prefix+'/Zappa-simple.js' then send client_bundle_simple
              when zappa_prefix+'/zappa.js' then send client
              when zappa_prefix+'/jquery.js' then send jquery_minified
              when zappa_prefix+'/sammy.js' then send sammy_minified
              else next()
          return
      session: (options) ->
        context.session_store = options.store
        session options

    use = (name, arg = null) ->
      if zappa_middleware[name]
        app.use zappa_middleware[name](arg)
      else if typeof express[name] is 'function'
        app.use use_middleware express[name](arg)
      else
        throw "Unknown middleware #{name}"

    for a in arguments
      switch typeof a
        when 'function' then app.use use_middleware a
        when 'string' then use a
        when 'object'
          if a.stack? or a.route? or a.handle?
            app.use a
          else
            use k, v for k, v of a
    return

  context.configure = (p) ->
    if typeof p is 'function' then app.configure p
    else app.configure k, v for k, v of p
    return

  context.settings = app.settings
  context.locals = app.locals

  context.shared = (obj) ->
    context.use 'zappa' unless zappa_used
    for k, v of obj
      js = ";zappa.run(#{v});"
      js = minify(js) if app.settings['minify']
      route verb: 'get', path: k, handler: js, contentType: 'js'
      v.apply context
    return

  context.include = (p) ->
    sub = if typeof p is 'string' then require path.join(root, p) else p
    sub.include.apply context

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

  # Local socket
  request_socket = (req) ->
    socket_id = req.session?.__socket?[app.settings.zappa_channel]?.id
    socket_id and io?.sockets.socket socket_id, true

  # The callback will receive (err,session).
  socket_session = (socket,cb) ->
    socket.get socketio_key, (err,data) ->
      if err
        return cb err
      data = JSON.parse data
      if data.id?
        context.session_store.get data.id, cb
      else
        cb err

  context.param = (obj) ->
    build = (callback) ->
      (req,res,next,p) ->
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

    for k, v of obj
      @app.param k, build v

    return

  # Register a route with express.
  route = (r) ->
    r.middleware ?= []

    # Rewrite middleware
    r.middleware = r.middleware.map wrap_middleware

    if typeof r.handler is 'string'
      app[r.verb] r.path, r.middleware, (req, res) ->
        res.contentType r.contentType if r.contentType?
        res.send r.handler
        return
    else
      app[r.verb] r.path, r.middleware, (req, res, next) ->
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
          emit: ->
            socket = request_socket req
            if socket?
              if typeof arguments[0] isnt 'object'
                socket.emit.apply socket, arguments
              else
                for k, v of arguments[0]
                  socket.emit.apply socket, [k, v]
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

          if app.settings['databag']
            opts.params = ctx.data

          if not opts.postrender?
            postrender = report
          else
            postrender = (err, str) ->
              if err then return report err
              # Apply postrender before sending response.
              jsdom.env html: str, src: [jquery], done: (err, window) ->
                if err then return report err
                ctx.window = window
                rendered = postrenders[opts.postrender].apply ctx, [window.$]

                doctype = (window.document.doctype or '') + "\n"
                html = doctype + window.document.documentElement.outerHTML
                report null, html
              return

          res.render.call res, name, opts, postrender

        apply_helpers ctx

        if app.settings['x-powered-by']
          res.setHeader 'X-Powered-By', "Zappa #{zappa.version}"

        result = r.handler.call ctx, req, res, next

        res.contentType(r.contentType) if r.contentType?
        if typeof result is 'string' then res.send result
        else return result

  # Register socket.io handlers.
  io?.sockets.on 'connection', (socket) ->
    c = {}

    build_ctx = ->
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
        emit: ->
          if typeof arguments[0] isnt 'object'
            socket.emit.apply socket, arguments
          else
            for k, v of arguments[0]
              socket.emit.apply socket, [k, v]
          return
        broadcast: ->
          broadcast = socket.broadcast
          if typeof arguments[0] isnt 'object'
            broadcast.emit.apply broadcast, arguments
          else
            for k, v of arguments[0]
              broadcast.emit.apply broadcast, [k, v]
          return
        broadcast_to: (room, args...) ->
          room = io.sockets.in room
          if typeof args[0] isnt 'object'
            room.emit.apply room, args
          else
            for k, v of args[0]
              room.emit.apply room, [k, v]
          return
        session: -> socket_session socket, arguments...

      apply_helpers ctx
      ctx

    ctx = build_ctx()
    ws_handlers.connection.apply(ctx) if ws_handlers.connection?

    socket.on 'disconnect', ->
      ctx = build_ctx()
      ws_handlers.disconnect.apply(ctx) if ws_handlers.disconnect?

    for name, h of ws_handlers
      do (name, h) ->
        if name isnt 'connection' and name isnt 'disconnect'
          socket.on name, (data, ack) ->
            ctx = build_ctx()
            ctx.data = data
            ctx.ack = ack
            h.call ctx, data, ack
        return
    return

  # Go!
  func.apply context

  # The stringified zappa client.
  client = require('./client').build(zappa.version, app.settings)
  client = ";#{coffeescript_helpers}(#{client})();"
  client_bundle_simple =
    if io?
      jquery + socketjs + client
    else
      jquery + client
  client_bundled =
    if io?
      jquery + socketjs + sammy + client
    else
      jquery + sammy + client

  if app.settings['minify']
    client = minify client
    client_bundle_simple = minify client_bundle_simple
    client_bundled = minify client_bundled

  if app.settings['default layout']
    context.view layout: ->
      extension = (path,ext) ->
        if path.substr(-(ext.length)).toLowerCase() is ext.toLowerCase()
          path
        else
          path + ext
      {doctype,html,head,title,script,link,style,body} = teacup
      ->
        doctype 5
        html ->
          head ->
            title @title if @title
            if @scripts
              for s in @scripts
                script src: extension s, '.js'
            script(src: extension @script, '.js') if @script
            if @stylesheets
              for s in @stylesheets
                link rel: 'stylesheet', href: extension s, '.css'
            link(rel: 'stylesheet', href: extension @stylesheet, '.css') if @stylesheet
            style @style if @style
          body @body

  if io?
    zappa_prefix = app.settings['zappa_prefix']
    context.get zappa_prefix+'/socket/:channel_name/:socket_id', ->
      if @session?
        channel_name = @params.channel_name
        socket_id = @params.socket_id

        @session.__socket ?= {}

        if @session.__socket[channel_name]?
          # Client (or hijacker) trying to re-key.
          @send error:'Channel already assigned', channel_name: channel_name
        else
          key = uuid.v4() # used for socket 'authorization'

          # Update the Express session store
          @session.__socket[channel_name] =
            id: socket_id
            key: key

          # Update the Socket.IO store
          io_client = io.sockets.store.client(socket_id)
          io_data = JSON.stringify
            id: @req.sessionID
            key: key
          io_client.set socketio_key, io_data

          # Let the client know which key to use.
          @send channel_name: channel_name, key: key
      else
        @send error:'No session'
      return

  context

# zappa.run [host,] [port,] [{options},] root_function
# Takes a function and runs it as a zappa app. Optionally accepts a port
# number, and/or a hostname (any order). The hostname must be a string, and
# the port number must be castable as a number.

zappa.run = ->
  host = null
  port = 3000
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
  app = zapp.app

  express_ready = ->
    log 'Express server listening on port %d in %s mode',
      zapp.server.address()?.port, app.settings.env
    log "Zappa #{zappa.version} orchestrating the show"

  if host
    zapp.server.listen port, host, express_ready
  else
    zapp.server.listen port, express_ready

  zapp

module.exports = zappa.run
module.exports.run = zappa.run
module.exports.app = zappa.app
module.exports.version = zappa.version

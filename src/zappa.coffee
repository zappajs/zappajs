# **Zappa** is a [CoffeeScript](http://coffeescript.org) DSL-ish interface
# for building web apps on the [node.js](http://nodejs.org) runtime,
# integrating [express](http://expressjs.com), [socket.io](http://socket.io)
# and other best-of-breed libraries.

zappa = version: (require '../package.json').version

log = console.log
fs = require 'fs'
path = require 'path'
util = require 'util'
uuid = require 'node-uuid'
methods = require 'methods'

session = require 'express-session'
serveStatic = require 'serve-static'

vendor_module = (module,args...) ->
  fs.readFileSync (path.join (path.dirname require.resolve module), args...), 'utf-8'

# Soft dependencies:
uglify = null
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
  uglify ?= require 'uglify-js'
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

invariate = (f) ->
  ->
    if typeof arguments[0] is 'object'
      for k,v of arguments[0]
        f.apply this, [k, v]
    else
      f.apply this, arguments

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

  context = {id: uuid.v4(), zappa, express, session}

  root = path.dirname module.parent.filename

  # Storage for user-provided stuff.
  ws_handlers = {}
  helpers = {}

  app = context.app = express()
  if options.https?
    context.server = require('https').createServer options.https, app
  else
    context.server = require('http').createServer app

  # Set options.io to false to disable socket.io.
  # Set options.io to socket.io's parameters otherwise (optional).
  io = null
  if options.io isnt false
    socketio = options.socketio ? require 'socket.io'
    io = context.io = socketio context.server, options.io ? {}

  # Reference to the zappa client, the value will be set later.
  client = null

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
          r = @engine views[@path], options, @path
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
  app.engine 'coffee zappa', (template,options) -> (teacup.renderable template).call options, options
  context.teacup = teacup

  app.set 'views', path.join(root, '/views')

  # Location of zappa-specific URIs.
  app.set 'zappa_prefix', '/zappa'

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

  context.client = invariate (k,v) ->
    context.use 'zappa' unless zappa_used
    js = ";zappa.run(#{v});"
    js = minify(js) if app.settings['minify']
    route verb: 'get', path: k, handler: js, type: 'js'
    return

  context.coffee = invariate (k,v) ->
    js = ";#{coffeescript_helpers}(#{v})();"
    js = minify(js) if app.settings['minify']
    route verb: 'get', path: k, handler: js, type: 'js'
    return

  context.js = invariate (k,v) ->
    js = String(v)
    js = minify(js) if app.settings['minify']
    route verb: 'get', path: k, handler: js, type: 'js'
    return

  context.css = invariate (k,v) ->
    if typeof v is 'object'
      coffee_css ?= require 'coffee-css'
      css = coffee_css.compile v
    else
      css = String(v)
    route verb: 'get', path: k, handler: css, type: 'css'
    return

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

  context.helper = invariate (k,v) ->
    helpers[k] = v
    return

  context.on = invariate (k,v) ->
    ws_handlers[k] = v
    return

  context.view = invariate (k,v) ->
    ext = path.extname k
    p = path.join app.get('views'), k
    if not ext
      p += '.' + app.get('view engine')
    views[p] = v
    return

  context.engine = invariate (k,v) ->
    app.engine k, v
    return

  context.set = invariate (k,v) ->
    app.set k, v
    return

  context.enable = ->
    app.enable i for i in arguments
    return

  context.disable = ->
    app.disable i for i in arguments
    return

  context.wrap = (f) ->
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
        send: -> res.send.apply res, arguments
        json: -> res.json.apply res, arguments
        jsonp: -> res.jsonp.apply res, arguments
        redirect: -> res.redirect.apply res, arguments
        format: -> res.format.apply res, arguments
      apply_helpers ctx
      f.call ctx, req, res, next

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
            res.type 'js'
            res.send code
          if req.method.toUpperCase() isnt 'GET' then next()
          else
            zappa_prefix = app.settings.zappa_prefix
            switch req.url
              when zappa_prefix+'/full.js' then send client_bundled()
              when zappa_prefix+'/simple.js' then send client_bundle_simple()
              when zappa_prefix+'/zappa.js' then send client
              when zappa_prefix+'/jquery.js' then send jquery_minified()
              when zappa_prefix+'/sammy.js' then send sammy_minified()
              when zappa_prefix+'/socket.io.js' then send socketjs()
              else next()
          return
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

  context.settings = app.settings
  context.locals = app.locals

  context.shared = invariate (k,v) ->
    context.use 'zappa' unless zappa_used
    js = ";zappa.run(#{v});"
    js = minify(js) if app.settings['minify']
    route verb: 'get', path: k, handler: js, type: 'js'
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

  build_param = (callback) ->
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

  context.param = invariate (k,v) ->
    @app.param k, build_param v
    return

  # Register a route with express.
  route = (r) ->
    r.middleware ?= []

    if typeof r.handler is 'string'
      app[r.verb] r.path, r.middleware, (req, res) ->
        res.type r.type if r.type?
        res.send r.handler
        return
    else if r.handler.call?
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
          emit: invariate (k,v) ->
            socket_id = req.session?.__socket?[app.settings.zappa_channel]?.id
            if socket_id?
              room = io.sockets.in socket_id
              room.emit.apply room, [k, v]
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

        res.type(r.type) if r.type?
        if typeof result is 'string' then res.send result
        else return result

    else
      throw new Error "ZappaJS invalid handler of type #{typeof r.handler}: #{util.inspect r.handler}"

  # Zappa local channel (the default channel used for @emit inside Zappa's own @get etc.
  app.set 'zappa_channel', '__local'

  # Register socket.io handlers.
  io?.sockets.on 'connection', (socket) ->
    c = {}
    session_id = null

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
        emit: invariate (k,v) ->
          socket.emit.apply socket, [k, v]
          return
        broadcast: invariate (k,v) ->
          broadcast = socket.broadcast
          broadcast.emit.apply broadcast, [k, v]
          return
        broadcast_to: (room, args...) ->
          room = io.sockets.in room
          broadcast = invariate (k,v) ->
            room.emit.apply room, [k, v]
          broadcast args...
          return

      apply_helpers ctx
      ctx

    # Wrap the handler for `connection`
    ctx = build_ctx()
    ws_handlers.connection.apply(ctx) if ws_handlers.connection?

    # Wrap the handler for `disconnect`
    socket.on 'disconnect', ->
      ctx = build_ctx()
      ws_handlers.disconnect.apply(ctx) if ws_handlers.disconnect?

    socket.on '__zappa_key', (data,ack) ->
      unless context.session_store?
        ack error:'Missing session-store.'
      unless data.key?
        ack error:'Missing key.'
        return
      # Retrieve the data record associated with the key.
      context.session_store.get data.key, (err,data) ->
        if err?
          ack error:err
          return
        if not data?
          ack error:'Missing data'
          return
        session_id = data.id
        ack yes

    get_session = (next) ->
      unless context.session_store? and session_id?
        next null
        return
      # Retrieve the session data stored by Express
      context.session_store.get session_id, (error,data) ->
        if error
          next null
          return
        next data

    # Wrap all other (event) handlers
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
        return
    return

  # Go!
  func.apply context

  jquery = -> jquery.content ?= app.settings.jquery_js ? vendor_module 'jquery', 'jquery.js'
  jquery_minified = -> jquery_minified.content ?= app.settings.jquery_min_js ? vendor_module 'jquery', 'jquery.min.js'
  sammy = -> sammy.content ?= app.settings.sammy_js ? vendor_module 'sammy', 'sammy.js'
  sammy_minified = -> sammy_minified.content ?= app.settings.sammy_min_js ? vendor_module 'sammy', 'min', 'sammy-latest.min.js'
  socketjs = -> socketjs.content ?= app.settings.socketio_js ? vendor_module 'socket.io-client', 'socket.io.js'

  # The stringified zappa client.
  client = require('./client').build(zappa.version, app.settings)
  client = ";#{coffeescript_helpers}(#{client})();"
  client_bundle_simple = -> client_bundle_simple.content ?=
    if io?
      jquery() + socketjs() + client
    else
      jquery() + client
  client_bundled = -> client_bundled.content ?=
    if io?
      jquery() + socketjs() + sammy() + client
    else
      jquery() + sammy() + client

  if app.settings['minify']
    client = minify client
    client_bundle_simple.content = minify client_bundle_simple()
    client_bundled.content = minify client_bundled()
    socketjs.content = minify socketjs()

  do ->
    zappa_prefix = app.settings.zappa_prefix
    context.get zappa_prefix+'/socket/:channel_name/:socket_id', ->
      if not context.session_store?
        @res.status 500
        @json error:'No session-store.'
        return

      if not @session?
        @res.status 400
        @json error:'No session'
        return

      channel_name = @params.channel_name
      socket_id = @params.socket_id

      @session.__socket ?= {}

      if @session.__socket[channel_name]?
        @json channel_name: channel_name, key: @session.__socket[channel_name].key
      else
        key = uuid.v4() # used for socket 'authentication'

        # Update the store.
        data =
          id: @session.id   # local Express Session ID
          cookie: {}
        context.session_store.set key, data, (err) =>
          if err
            @json error: err.toString()
            return

          # Update the Express session store
          @session.__socket[channel_name] =
            id: socket_id
            key: key

          # Let the client know which key to use.
          @json channel_name: channel_name, key: key
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
  {server,app} = zapp

  express_ready = ->
    addr = server.address()
    log """
      Express server listening on #{addr.address}:#{addr.port} in #{app.settings.env} mode.
      Zappa #{zappa.version} orchestrating the show.

    """

  if host
    server.listen port, host, express_ready
  else
    server.listen port, express_ready

  zapp

module.exports = zappa.run
module.exports.run = zappa.run
module.exports.app = zappa.app
module.exports.version = zappa.version

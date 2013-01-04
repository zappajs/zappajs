# Client-side zappa.
skeleton = ->
  zappa = window.zappa = {}
  zappa.version = null

  settings = null

  zappa.run = (func) ->
    context = {}

    # Storage for the functions provided by the user.
    ws_handlers = []
    helpers = {}

    apply_helpers = (ctx) ->
      for name, helper of helpers
        do (name, helper) ->
          if typeof helper is 'function'
            ctx[name] = ->
              helper.apply ctx, arguments
          else
            ctx[name] = helper
      ctx

    app = context.app = Sammy() if Sammy?

    context.get = ->
      if typeof arguments[0] isnt 'object'
        route path: arguments[0], handler: arguments[1]
      else
        for k, v of arguments[0]
          route path: k, handler: v

    context.helper = (obj) ->
      for k, v of obj
        helpers[k] = v

    context.on = (obj) ->
      for message, action  of obj
        ws_handlers.push {message,action}

    context.connect = ->
      context.socket = io.connect.apply io, arguments

    context.emit = ->
      if typeof arguments[0] isnt 'object'
        context.socket.emit.apply context.socket, arguments
      else
        for k, v of arguments[0]
          context.socket.emit.apply context.socket, [k, v]

    context.share = (channel,socket,cb) ->
      $.getJSON "/zappa/socket/#{channel}/#{socket.socket.sessionid}", cb

    route = (r) ->
      ctx = {app}

      apply_helpers ctx

      app.get r.path, (sammy_context) ->
        ctx.params = sammy_context.params
        ctx.sammy_context = sammy_context
        ctx.render = -> sammy_context.render.apply sammy_context, arguments
        ctx.redirect = -> sammy_context.redirect.apply sammy_context, arguments
        r.handler.apply ctx

    # GO!!!
    func.apply(context, [context])

    # Implements the websockets client with socket.io.
    if context.socket?
      context.socket.on 'connect', ->
        context.share '__local', context.socket, (data) ->
          context.key = data.key

      for {message,action} in ws_handlers
        do (message, action) ->
          context.socket.on message, (data) ->
            ctx =
              app: app
              socket: context.socket
              id: context.socket.id
              data: data
              emit: context.emit
              share: context.share

            apply_helpers ctx

            action.apply ctx

    $(-> app.run '#/') if app?

@build = (version, settings) ->
  String(skeleton)
    .replace('version = null;', "version = '#{version}';")
    .replace('settings = null;', "var settings = #{JSON.stringify settings};")

# Client-side zappa.
skeleton = ->
  zappa = window.zappa = {}
  zappa.version = null

  settings = null

  invariate = (f) ->
    ->
      if typeof arguments[0] is 'object'
        for k,v of arguments[0]
          f.apply this, [k, v]
      else
        f.apply this, arguments

  zappa.run = (func) ->
    context = {}

    context.settings = settings

    # Storage for the functions provided by the user.
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

    context.get = invariate (k,v) ->
      route path: k, handler: v

    context.helper = invariate (k,v) ->
      helpers[k] = v

    context.on = invariate (message,action) ->
      context.socket.on message, (data) ->
        ctx =
          app: app
          socket: context.socket
          id: context.socket.id
          data: data
          emit: context.emit
          share: context.share
        apply_helpers ctx
        action.call ctx, data

    context.connect = ->
      return unless io?
      context.socket = io.apply io, arguments

    context.emit = invariate (message,data) ->
      context.socket.emit.apply context.socket, [message, data]

    # The callback will receive `true` iff the operation was successful
    # Might receive an object in case of error, or simply `false`.
    context.share = (channel_name,socket,next) ->
      zappa_prefix = settings.zappa_prefix ? ""
      socket_id = socket.id
      if not socket_id?
        next? false
        return
      $.getJSON "#{zappa_prefix}/socket/#{channel_name}/#{socket_id}"
      .done ({key}) ->
        if key?
          socket.emit '__zappa_key', {key}, next
        else
          next? false
      .fail ->
        next? false

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
        context.share settings.zappa_channel, context.socket

    $(-> app.run '#/') if app?

@build = (version, settings) ->
  String(skeleton)
    .replace('version = null;', "version = '#{version}';")
    .replace('settings = null;', "settings = #{JSON.stringify settings};")

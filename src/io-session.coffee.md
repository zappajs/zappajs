    pkg = require '../package.json'
    debug = (require 'debug') "#{pkg.name}:io-session"
    uuid = require 'node-uuid'

Express-side API to bind with Socket.IO
=======================================

API used by the client (e.g. `zappajs-client`) to create an Express-side key that will be used to bind Express and Socket.io sessions.

    @bind_express = ({context}) ->
        {app} = context

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
              @res.status 500
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

Retrieve the session
====================

Socket.io-side retrieval of the bound session.

Bind with Express
-----------------

The special event `__zappa_key` is used by the client to notify us of the key provided by Express.

    @bind_io = ({context}) ->

        context.on '__zappa_key', ({key},ack) ->

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

          context.session_store.get key, (err,data) =>
            if err?
              debug 'session_store.get #{key}: #{err}'
              ack error:err.toString()
              return
            if not data?
              debug 'session_store.get #{key}: Missing data'
              ack error:'Missing data'
              return

Bind the session.id so that the handlers can access the session.

            @client.__session_id = data.id
            ack {key}

Middleware for sockets
======================

    @bind_middleware = ({context}) ->

        get_session = (ctx,next) ->

          unless context.session_store?
            debug 'Session Store is not ready, `@session` will not be available.'
            next()
            return

If no Express session was bound, we use the (local) socket.id as session identifier.
This allows this code to provide session support in both cases.

          session_id = ctx.client.__session_id ? ctx.id
          req =
            sessionID: session_id
            sessionStore: context.session_store

Retrieve the session data stored by Express

          context.session_store.get session_id, (error,data) ->
            if error and error.code isnt 'ENOENT'
              next error
              return

            data ?= cookie: __io: true

Set `@req.session` just like Express-session does, and add a `@session` shortcut just like Zappa does.

            ctx.session = ctx.req.session = new context.session.Session req, data
            next()
            return

        context.io_use (ctx,res,next) ->
          get_session ctx, ->
            v = next()
            if v?.then?
              v.then -> ctx.session?.save()
            else
              ctx.session?.save()

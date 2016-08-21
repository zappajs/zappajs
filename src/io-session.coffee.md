    pkg = require '../package.json'
    debug = (require 'debug') "#{pkg.name}:bind-io-session"

Express-side API to bind with Socket.IO
=======================================

API used by the client (e.g. `zappajs-client`) to create an Express-side key that will be used to bind Express and Socket.io sessions.

    exports.bind = ({app,context}) ->

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

Retrieve the session
====================

Socket.io-side retrieval of the bound session.

    exports.get = ({socket,app,context}) ->

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
            debug 'Session Store is not ready, `@session` will not be available.'
            next null
            return

          req =
            sessionID: session_id
            sessionStore: context.session_store

Retrieve the session data stored by Express

          context.session_store.get session_id, (error,data) ->
            if error
              debug "get_session() #{error}"
              next null
              return
            req.session = new context.session.Session req, data
            next req.session

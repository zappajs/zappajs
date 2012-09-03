#!/usr/bin/coffee
#
# This examples show how data can be shared between Express and Socket.IO.
# You must run share_socketio.coffee in parallel to this script.
#

require('./zappajs') 3000, ->

  @use 'logger',
    'cookieParser',
    'partials',
  @enable 'default layout'

  express_store = do =>
    ExpressRedisStore = require('connect-redis') @express
    new ExpressRedisStore()

  @use session:
    store: express_store
    secret: 'rock zappa rock'

  socketio_store = do ->
    SocketIORedisStore = require 'socket.io/lib/stores/redis'
    redis = require 'redis'
    pub = redis.createClient()
    sub = redis.createClient()
    client = redis.createClient()
    new SocketIORedisStore
      redisPub: pub
      redisSub: sub
      redisClient: client

  @io.set 'store', socketio_store

  @get '/': ->
    @render 'default',
      scripts: '/socket.io/socket.io /zappa/jquery /zappa/zappa /index'.split ' '

  @get '/touch': ->
    @session.foo = 'bar'
    @send ok:true

  @get '/verify': ->
    @send foo:@session.foo

  @view default: ->
    div id:'log'

  @client '/index.js': ->

    $ =>
      log = -> $('#log').append arguments...
      socket = null

      @connect()

      channel_name = Math.random()

      # connect to the separate Socket.IO process.
      socket = io.connect 'http://127.0.0.1:3001'
      socket.on 'connect', =>
        @share channel_name, socket, (data) ->
          log "<p>Received key #{data.key} for channel #{data.channel_name}</p>"
          $.getJSON "/touch", (data) ->
            $.getJSON "/verify", (data) ->
              log "<p>Express says that foo = #{data.foo}</p>"
              socket.emit 'express done, your turn'

      socket.on 'all set', (data) ->
        log "<p>Socket says that foo = #{data.foo}.</p>"

      log '<p>Client started.</p>'

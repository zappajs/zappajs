#!/usr/bin/coffee
#
# This examples show how data can be shared between Express and Socket.IO.
# You must run share_express.coffee in parallel to this script.
#
# This is the "Socket.IO only" side of the experiment.

require('./zappajs') 3001, ->

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

  @on 'express done, your turn': ->
    @session (err,session) =>
      # Let the client confirm that we received the session data OK.
      @emit 'all set', foo: session.foo

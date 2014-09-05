@include = ->

  redis_config = require './redis_config'

  ExpressRedisStore = (require 'connect-redis') @session
  @use session:
    store: new ExpressRedisStore redis_config
    secret: 'rock zappa rock'

  SocketIORedisStore = require 'socket.io-redis'
  @io.adapter SocketIORedisStore redis_config

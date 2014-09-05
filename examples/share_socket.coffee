#!/usr/bin/coffee
#
# This examples show how data can be shared between Express and Socket.IO.
# You must run share_express.coffee in parallel to this script.
#
# This is the "Socket.IO only" side of the experiment.

require('./zappajs') 3001, ->

  @include 'redis_setup'

  @on 'express done, your turn': ->
    @session (err,session) =>
      # Let the client confirm that we received the session data OK.
      @emit 'all set', foo: session.foo

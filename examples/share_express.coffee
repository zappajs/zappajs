#!/usr/bin/coffee
#
# This examples show how data can be shared between Express and Socket.IO.
# You must run share_socketio.coffee in parallel to this script
# and have a Redis server instance running (e.g. `docker run --net=host shimaore/redis-server`).
#

# No cheating: we start ZappaJS without Socket.IO!
require('./zappajs') 3000, io:false, ->

  @use morgan:'combined', 'cookie-parser'

  @include './redis_setup'

  @get '/': ->
    @render 'default',
      scripts: '/index'.split ' '

  @get '/touch': ->
    @session.foo = 'bar'
    @send ok:true

  @get '/verify': ->
    @send foo:@session.foo

  {doctype,html,head,script,body,div} = @teacup
  @view default: ->
    doctype 5
    html =>
      head =>
        script src:"#{s}.js" for s in @scripts
      body ->
        div id:'log'

  @with 'client'
  @browser '/index.js': ->
    Zappa = require 'zappajs-client'

    Zappa io:'http://127.0.0.1:3001', ->
      @ready ->
        $ = require 'component-dom'
        log = -> $('#log').append arguments...

        @request
        .get '/touch'
        .then ({body}) =>
          @request
          .get '/verify'
        .then ({body}) =>
          log "<p>Express says that foo = #{body.foo}</p>"
          @emit 'express done, your turn'

        @on 'all set', (data) ->
          log "<p>Socket says that foo = #{data.foo}.</p>"

        log '<p>Client started.</p>'

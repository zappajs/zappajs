#!/usr/bin/coffee
#
# This examples show how data can be shared between Express and Socket.IO.
# You must run share_socketio.coffee in parallel to this script.
#

# No cheating: we start ZappaJS without Socket.IO!
require('./zappajs') 3000, io:false, ->

  @use morgan:'combined', 'cookie-parser'

  @include './redis_setup'

  @get '/': ->
    @render 'default',
      scripts: '/zappa/socket.io /zappa/simple /index'.split ' '

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

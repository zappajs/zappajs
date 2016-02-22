require('./zappajs') ->
  @with 'client'
  @use session: store: new @session.MemoryStore(), secret: 'foo', resave: true, saveUninitialized: true

  @get '/': ->
    @render 'index'

  @on 'set nickname': ->
    @client.nickname = @data.nickname
    @emit 'said', {nickname: 'moderator', msg: 'Your name is ' + @data.nickname}

  @on 'set room': ->
    @leave(@client.room) if @client.room
    @client.room = @data.room
    @join(@data.room)
    @emit 'said', {nickname: 'moderator', msg: 'You joined room ' + @data.room}

  @on said: ->
    data =
      nickname: @client.nickname
      msg: @data.msg
    @broadcast_to @client.room, 'said', data

  @client '/index.js': ->
    $ = require 'component-dom'

    @on said: ->
      $('#panel').append "<p>#{@data.nickname} said: #{@data.msg}</p>"

    @emit 'set nickname': {nickname: prompt 'Pick a nickname!'}
    @emit 'set room': {room: prompt 'Pick a room!'}

    $('#box').focus()

    $('#sendButton').on 'click', (e) =>
      @emit said: {msg: $('#box').value()}
      $('#box').value('').focus()
      e.preventDefault()

    $('#changeButton').on 'click', (e) =>
      @emit 'set room': {room: prompt 'Pick a room!'}
      $('#box').value('').focus()
      e.preventDefault()

  {doctype,html,head,title,script,body,div,form,input,button} = @teacup
  @view index: ->
    doctype 5
    html ->
      head ->
        title 'PicoRoomChat!'
        script src: '/zappa/simple.js'
        script src: '/index.js'
      body ->
        div id: 'panel'
        form ->
          input id: 'box'
          button id: 'sendButton', -> 'Send Message'
          button id: 'changeButton', -> 'Change Room'

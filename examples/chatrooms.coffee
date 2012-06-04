require('./zappajs') ->
  @enable 'serve jquery'
  
  @get '/': ->
    @render index: {layout: no}
  
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
    @broadcast_to_all @client.room, 'said', data
 
  @client '/index.js': ->
    @connect()

    @on said: ->
      $('#panel').append "<p>#{@data.nickname} said: #{@data.msg}</p>"
    
    $ =>
      @emit 'set nickname': {nickname: prompt 'Pick a nickname!'}
      @emit 'set room': {room: prompt 'Pick a room!'}
      
      $('#box').focus()
      
      $('#sendButton').click (e) =>
        @emit said: {msg: $('#box').val()}
        $('#box').val('').focus()
        e.preventDefault()

      $('#changeButton').click (e) =>
        @emit 'set room': {room: prompt 'Pick a room!'}
        $('#box').val('').focus()
        e.preventDefault()

  @view index: ->
    doctype 5
    html ->
      head ->
        title 'PicoRoomChat!'
        script src: '/socket.io/socket.io.js'
        script src: '/zappa/jquery.js'
        script src: '/zappa/zappa.js'
        script src: '/index.js'
      body ->
        div id: 'panel'
        form ->
          input id: 'box'
          button id: 'sendButton', -> 'Send Message'
          button id: 'changeButton', -> 'Change Room'

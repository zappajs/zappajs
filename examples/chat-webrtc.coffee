require('./zappajs') ->

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
        room = prompt 'Pick a room!'
        @emit 'set room': {room}
        webrtc.joinRoom room
        $('#box').val('').focus()
        e.preventDefault()

      webrtc = new SimpleWebRTC
        # the id/element dom element that will hold "our" video
        localVideoEl: 'localVideo',
        # the id/element dom element that will hold remote videos
        remoteVideosEl: 'remotesVideos',
        # immediately ask for camera access
        autoRequestMedia: true

      # we have to wait until it's ready
      webrtc.on 'readyToCall', ->
        # you can name it anything

  {doctype,html,head,title,script,body,div,form,input,button,video} = @teacup
  @view index: ->
    doctype 5
    html ->
      head ->
        title 'PicoRoomChat!'
        script src: '/zappa/simple.js'
        script src: '/index.js'
        script src: '//simplewebrtc.com/latest.js'
      body ->
        div id: 'panel'
        form ->
          input id: 'box'
          button id: 'sendButton', -> 'Send Message'
          button id: 'changeButton', -> 'Change Room'
        video '#localVideo', height:300
        div '#remotesVideos'

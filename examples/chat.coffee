require('./zappajs') ->
  @with 'client'
  @use session: store: new @session.MemoryStore(), secret: 'foo', resave: true, saveUninitialized: true

  @get '/': ->
    @render 'index'

  @on 'set nickname': ->
    @client.nickname = @data.nickname

  @on said: ->
    @broadcast said: {nickname: @client.nickname, text: @data.text}
    @emit said: {nickname: @client.nickname, text: @data.text}

  @client '/index.js': ->
    $ = require 'component-dom'
    @emit 'set nickname': {nickname: prompt 'Pick a nickname!'}

    @on said: ->
      $('#panel').append "<p>#{@data.nickname} said: #{@data.text}</p>"

    $('#box').focus()

    ($ 'button').on 'click', (e) =>
      @emit said: {text: $('#box').value()}
      $('#box').value('').focus()
      e.preventDefault()

  {doctype,html,head,title,script,body,div,form,input,button} = @teacup
  @view index: ->
    doctype 5
    html ->
      head ->
        title 'PicoChat!'
        script src: '/zappa/simple.js'
        script src: '/index.js'
      body ->
        div id: 'panel'
        form ->
          input id: 'box'
          button 'Send'

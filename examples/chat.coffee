require('./zappajs') ->

  @get '/': ->
    @render index: {layout: no}

  @on 'set nickname': ->
    @client.nickname = @data.nickname

  @on said: ->
    @broadcast said: {nickname: @client.nickname, text: @data.text}
    @emit said: {nickname: @client.nickname, text: @data.text}

  @client '/index.js': ->
    @connect()

    $ =>
      @emit 'set nickname': {nickname: prompt 'Pick a nickname!'}

      @on said: ->
        $('#panel').append "<p>#{@data.nickname} said: #{@data.text}</p>"

      $('#box').focus()

      $('button').click (e) =>
        @emit said: {text: $('#box').val()}
        $('#box').val('').focus()
        e.preventDefault()

  {doctype,html,head,title,script,body,div,form,input,button} = @teacup
  @view index: ->
    doctype 5
    html ->
      head ->
        title 'PicoChat!'
        script src: '/zappa/Zappa-simple.js'
        script src: '/index.js'
      body ->
        div id: 'panel'
        form ->
          input id: 'box'
          button 'Send'

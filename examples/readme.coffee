# This is the example from README.md
require('./zappajs') ->

  ## Server-side ##
  teacup = @teacup

  @get '/': ->
    @render 'index',
      title: 'Zappa!'
      scripts: '/index.js /more.js /client.js'
      stylesheet: '/index.css'

  @view index: ->
    {doctype,html,head,title,script,link,body,h1,div} = teacup
    doctype 5
    html =>
      head =>
        title @title if @title
        for s in @scripts.split ' '
          script src: s
        link rel:'stylesheet', href:@stylesheet
      body ->
        h1 'Welcome to Zappa!'
        div id:'content'
        div id:'content2'

  pixels = 12

  @css '/index.css':
    body:
      font: '12px Helvetica'
    h1:
      color: 'pink'
      height: "#{pixels}px"

  @get '/:name/data.json': ->
    record =
      id: 123
      name: @params.name
      email: "#{@params.name}@example.com"
    @json record

  ## Client-side ##
  @coffee '/index.js': ->
    alert 'hi'

  ## Client-side with Browserify ##
  @browser '/more.js': ->
    domready = require 'domready'
    $ = require 'component-dom'
    domready ->
      $('#content').html 'Ready to roll!'

  ## Client-side with ExpressJS/Socket.IO session sharing ##
  @with 'client' # requires `zappajs-plugin-client`
  @use session:
    store: new @session.MemoryStore()
    secret: 'foo'
    resave: true, saveUninitialized: true

  @on 'ready': ->
    console.log "Client #{@id} is ready and says #{@data}."
    @emit 'ok', null

  @client '/client.js': ->
    @emit 'ready', 'hello'
    console.log 'A'
    $ = require 'component-dom'
    console.log 'B'
    @on 'ok', ->
      $('#content2').html 'Ready to roll too!'

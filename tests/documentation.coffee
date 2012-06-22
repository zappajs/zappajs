# The examples from the documentation (under /docs) should be tested here.

zappa = require '../src/zappa'
port = 16000

@tests =
  crashcourse_1: (t) ->
    t.expect 1
    t.wait 3000

    zapp = zappa port++, ->
      @get '/': 'hi'

    c = t.client(zapp.app)
    c.get '/', (err, res) ->
      t.equal 1, res.body, 'hi'

  crash_course_2: (t) ->
    t.expect 1,2
    t.wait 3000

    zapp = zappa port++, ->
      @app.get '/', (req, res) ->
        res.send 'boring!'
      @io.sockets.on 'connection', (socket) ->
        socket.emit 'boring'

    c = t.client(zapp.app)
    c.connect()
    c.get '/', (err, res) ->
      t.equal 1, res.body, 'boring!'
    c.on 'boring', ->
      t.reached 2

  crashcourse_3: (t) ->
    t.expect 1,2,3
    t.wait 3000

    zapp = zappa port++, ->

      @get '/foo': 'bar', '/ping': 'pong', '/zig': 'zag'
      @use 'bodyParser', 'methodOverride', @app.router, 'static'
      @set 'view engine': 'jade', views: "#{__dirname}/custom/dir"

    c = t.client(zapp.app)
    c.get '/foo', (err,res) ->
      t.equal 1, res.body, 'bar'
    c.get '/ping', (err,res) ->
      t.equal 2, res.body, 'pong'
    c.get '/zig', (err,res) ->
      t.equal 3, res.body, 'zag'

  crashcourse_4: (t) ->
    t.expect 1
    t.wait 3000

    zapp = zappa port++, (foo) ->
      foo.get '/': 'hi'

    c = t.client(zapp.app)
    c.get '/', (err,res) ->
      t.equal 1, res.body, 'hi'

  crashcourse_5: (t) ->
    t.expect 1
    t.wait 3000

    zapp = zappa.app ->
      @get '/': 'hi'
    zapp.app.server.listen port++

    c = t.client(zapp.app)
    c.get '/', (err,res) ->
      t.equal 1, res.body, 'hi'

  crashcourse_6: (t) ->
    t.expect 1
    t.wait 3000

    zapp = zappa port++, ->
      @get '*': '''
        <!DOCTYPE html>
        <html>
          <head><title>Oops</title></head>
          <body><h1>Sorry, check back in a few minutes!</h1></body>
        </html>
      '''

    c = t.client(zapp.app)
    c.get '/foo', (err,res) ->
      t.equal 1, res.body, '''
        <!DOCTYPE html>
        <html>
          <head><title>Oops</title></head>
          <body><h1>Sorry, check back in a few minutes!</h1></body>
        </html>
      '''

  crashcourse_7: (t) ->
    t.expect 1,2,3
    t.wait 3000

    zapp = zappa port++, ->
      @get '/:name': ->
        "Hi, #{@params.name}"

    c = t.client(zapp.app)
    c.get '/foo', (err,res) ->
      t.equal 1, res.body, 'Hi, foo'
    c.get '/bar', (err,res) ->
      t.equal 2, res.body, 'Hi, bar'
    c.get '/%c3%a0%c3%a9%c3%b6%c3%b1', (err,res) ->
      t.equal 3, res.body, 'Hi, àéöñ'

  crashcourse_8: (t) ->
    t.expect 1,2,3
    t.wait 3000

    zapp = zappa port++, ->
      @get '/:name': (foo) ->
        "Hi, #{foo.params.name}"

    c = t.client(zapp.app)
    c.get '/foo', (err,res) ->
      t.equal 1, res.body, 'Hi, foo'
    c.get '/bar', (err,res) ->
      t.equal 2, res.body, 'Hi, bar'
    c.get '/%c3%a0%c3%a9%c3%b6%c3%b1', (err,res) ->
      t.equal 3, res.body, 'Hi, àéöñ'

  crashcourse_9: (t) ->
    t.expect 1,2
    t.wait 3000

    Poncho =
      findById: (id,fn) ->
        if id.match /^s/
          fn null, type:'sears'
        else
          fn null, type:'real'

    zapp = zappa port++, ->
     @get '/ponchos/:id': ->
      Poncho.findById @params.id, (err, poncho) =>
        # Is that a real poncho, or is that a sears poncho?
        @send poncho.type

    c = t.client(zapp.app)
    c.get '/ponchos/foo', (err,res) ->
      t.equal 1, res.body, 'real'
    c.get '/ponchos/salt', (err,res) ->
      t.equal 2, res.body, 'sears'

# at line 122 of crashcourse.md

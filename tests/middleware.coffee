zappa = require '../src/zappa'
port = 15500

@tests =
  'vanilla express API': (t) ->
    t.expect 'static', 'response time'
    t.wait 3000

    zapp = zappa port++, ->
      @app.use @express.static(__dirname + '/public')
      @app.use (require 'response-time')()

    c = t.client(zapp.server)
    c.get '/foo.txt', (err, res) ->
      t.equal 'static', res.body, 'bar'

    c.get '/', (err, res) ->
      t.ok 'response time', res.headers['x-response-time'].match /\d+ms/

  'array express API': (t) ->
    t.expect 'array'
    t.wait 3000

    zapp = zappa port++, ->
      foo = bar = baz = ->
        @next()
      common = [foo, bar, baz].map @wrap

      @get '/something', common..., -> 'ok'
      @get '/something2', common, -> 'ok'

    c= t.client(zapp.server)
    c.get '/something', (err, res) ->
      t.equal 'array', res.body, 'ok'
    c.get '/something2', (err, res) ->
      t.equal 'array', res.body, 'ok'

  use: (t) ->
    t.expect 'static', 'response time'
    t.wait 3000

    zapp = zappa port++, ->
      @use @express.static(__dirname + '/public'), (require 'response-time')()

    c = t.client(zapp.server)
    c.get '/foo.txt', (err, res) ->
      t.equal 'static', res.body, 'bar'

    c.get '/', (err, res) ->
      t.ok 'response time', res.headers['x-response-time'].match /\d+ms/

  'use + shortcuts': (t) ->
    t.expect 'static', 'response time'
    t.wait 3000

    zapp = zappa port++, ->
      @use static: __dirname + '/public', 'response-time'

    c = t.client(zapp.server)
    c.get '/foo.txt', (err, res) ->
      t.equal 'static', res.body, 'bar'

    c.get '/', (err, res) ->
      t.ok 'response time', res.headers['x-response-time'].match /\d+ms/

  'use + shortcuts + zappa added defaults': (t) ->
    t.expect 'static', 'response time'
    t.wait 3000

    zapp = zappa port++, ->
      @use 'static', 'response-time'

    c = t.client(zapp.server)
    c.get '/foo.txt', (err, res) ->
      t.equal 'static', res.body, 'bar'

    c.get '/', (err, res) ->
      t.ok 'response time', res.headers['x-response-time'].match /\d+ms/

  ###
  # This test is broken in Express 4
  #
  precedence: (t) ->
    t.expect 'static'
    t.wait 3000

    zapp = zappa port++, ->
      @use 'static'
      @get '/foo.txt': 'intercepted!'

    c = t.client(zapp.server)
    c.get '/foo.txt', (err, res) ->
      t.equal 'static', res.body, 'intercepted!'
  #
  ###

  precedence_2: (t) ->
    t.expect 'static'
    t.wait 3000

    zapp = zappa port++, ->
      @get '/foo.txt': 'intercepted!'
      @use 'static'

    c = t.client(zapp.server)
    c.get '/foo.txt', (err, res) ->
      t.equal 'static', res.body, 'intercepted!'



  compatible: (t) ->
    t.expect 1, 2, 3
    t.wait 3000

    zapp = zappa port++, ->
      auth = -> (user,pass) ->
        user is 'hello' and pass is 'world'

      authenticator = @wrap ->
        credentials = (require 'basic-auth') @req
        if not credentials or not auth credentials.name, credentials.pass
          @res.writeHead 401, 'WWW-Authenticate': 'Basic realm="example"'
          @res.end()
        else
          @next()

      @get '/', -> 'welcome'
      @get '/auth', authenticator, -> 'authenticated'

    c = t.client(zapp.server)
    c.get '/', (err, res) ->
      t.equal 1, res.body, 'welcome'

    c.get '/auth', (err, res) ->
      t.equal 2, res.statusCode, 401

    a = new Buffer('hello:world').toString('base64')
    c.get '/auth', headers: {Authorization:'Basic '+a}, (err, res) ->
      t.equal 3, res.body, 'authenticated'

  'static + noparams': (t) ->
    t.expect 'static'
    t.wait 3000

    zapp = zappa port++, ->
      @use 'static'

    c = t.client(zapp.server)
    c.get '/foo.txt', (err, res) ->
      t.equal 'static', res.body, 'bar'

  'static + string': (t) ->
    t.expect 'static'
    t.wait 3000

    zapp = zappa port++, ->
      @use static: __dirname + '/public'

    c = t.client(zapp.server)
    c.get '/foo.txt', (err, res) ->
      t.equal 'static', res.body, 'bar'

  'static + object': (t) ->
    t.expect 'static'
    t.wait 3000

    zapp = zappa port++, ->
      @use static: {path: __dirname + '/public', maxAge:60}

    c = t.client(zapp.server)
    c.get '/foo.txt', (err, res) ->
      t.equal 'static', res.body, 'bar'

  'no magic middleware': (t) ->
    t.expect 1
    t.wait 3000

    zapp = zappa port++, ->
      mw = (req,res,next) ->
        res.locals.foo = 'bar'
        next()
      @use mw
      @get '/', ->
          @send @locals.foo

    c = t.client(zapp.server)
    c.get '/', (err, res) ->
      t.equal 1, res.body, 'bar'

  'no magic middleware, wrapped middleware': (t) ->
    t.expect 1
    t.wait 3000

    zapp = zappa port++, ->
      mw = ->
        @locals.foo = 'bar'
        @next()
      @use @wrap mw
      @get '/', ->
          @send @locals.foo

    c = t.client(zapp.server)
    c.get '/', (err, res) ->
      t.equal 1, res.body, 'bar'

  'wrapped middleware, inline': (t) ->
    t.expect 1
    t.wait 3000

    zapp = zappa port++, ->
      mw = @wrap ->
        @locals.foo = 'bar'
        @next()
      @get '/', mw, ->
          @send @locals.foo

    c = t.client(zapp.server)
    c.get '/', (err, res) ->
      t.equal 1, res.body, 'bar'

  all: (t) ->
    t.expect '1', '2', '3', '4'
    t.wait 4000

    zapp = zappa port++, ->

      @all '/*', ->
        if @query.hello is 'hi' then @next()
        else @next new Error 'Where is your manners?'

      @get '/bonjour', ->
        @send 'bonjour'

      @get '/hola', ->
        @send 'hola!'

    c = t.client(zapp.server)
    c.get '/bonjour?hello=hi', (err, res) ->
      t.equal '1', res.body, 'bonjour'
    c.get '/bonjour', (err, res) ->
      t.ok '2', res.body.match /Where is your manners\?/
    c.get '/hola?hello=hi', (err, res) ->
      t.equal '3', res.body, 'hola!'
    c.get '/hola?hello=boo', (err, res) ->
      t.ok '4', res.body.match /Where is your manners\?/

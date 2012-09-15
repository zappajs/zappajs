zappa = require '../src/zappa'
port = 15500

@tests =
  'vanilla express API': (t) ->
    t.expect 'static', 'response time'
    t.wait 3000
    
    zapp = zappa port++, ->
      @app.use @express.static(__dirname + '/public')
      @app.use @express.responseTime()
    
    c = t.client(zapp.server)
    c.get '/foo.txt', (err, res) ->
      t.equal 'static', res.body, 'bar'
    
    c.get '/', (err, res) ->
      t.ok 'response time', res.headers['x-response-time'].match /\d+ms/

  use: (t) ->
    t.expect 'static', 'response time'
    t.wait 3000
    
    zapp = zappa port++, ->
      @use @express.static(__dirname + '/public'), @express.responseTime()
    
    c = t.client(zapp.server)
    c.get '/foo.txt', (err, res) ->
      t.equal 'static', res.body, 'bar'
    
    c.get '/', (err, res) ->
      t.ok 'response time', res.headers['x-response-time'].match /\d+ms/

  'use + shortcuts': (t) ->
    t.expect 'static', 'response time'
    t.wait 3000
    
    zapp = zappa port++, ->
      @use static: __dirname + '/public', 'responseTime'
    
    c = t.client(zapp.server)
    c.get '/foo.txt', (err, res) ->
      t.equal 'static', res.body, 'bar'
    
    c.get '/', (err, res) ->
      t.ok 'response time', res.headers['x-response-time'].match /\d+ms/

  'use + shortcuts + zappa added defaults': (t) ->
    t.expect 'static', 'response time'
    t.wait 3000
    
    zapp = zappa port++, ->
      @use 'static', 'responseTime'
    
    c = t.client(zapp.server)
    c.get '/foo.txt', (err, res) ->
      t.equal 'static', res.body, 'bar'
    
    c.get '/', (err, res) ->
      t.ok 'response time', res.headers['x-response-time'].match /\d+ms/

  precedence: (t) ->
    t.expect 'static'
    t.wait 3000
    
    zapp = zappa port++, ->
      @use @app.router, 'static'
      @get '/foo.txt': 'intercepted!'
    
    c = t.client(zapp.server)
    c.get '/foo.txt', (err, res) ->
      t.equal 'static', res.body, 'intercepted!'

  all: (t) ->
    t.expect '1', '2', '3', '4'
    t.wait 4000

    zapp = zappa port++, ->

      @all '/*', ->
        if @query.hello is 'hi' then @next()
        else @next 'Where is your manners?'
      
      @get '/bonjour', ->
        @send 'bonjour'

      @get '/hola', ->
        @send 'hola!'

    c = t.client(zapp.server)
    c.get '/bonjour?hello=hi', (err, res) ->
      t.equal '1', res.body, 'bonjour'
    c.get '/bonjour', (err, res) ->
      t.equal '2', res.body, 'Where is your manners?'
    c.get '/hola?hello=hi', (err, res) ->
      t.equal '3', res.body, 'hola!'
    c.get '/hola?hello=boo', (err, res) ->
      t.equal '4', res.body, 'Where is your manners?'



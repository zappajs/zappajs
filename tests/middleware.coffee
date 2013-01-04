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

  'array express API': (t) ->
    t.expect 'array'
    t.wait 3000

    zapp = zappa port++, ->
      foo = bar = baz = ->
        @next()
      common = [foo, bar, baz]

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

zappa = require '../src/zappa'
port = 15200
vm = require 'vm'

JS_TYPE = 'application/javascript; charset=utf-8'
CSS_TYPE = 'text/css; charset=utf-8'

@tests =
  client: (t) ->
    t.expect 1, 2
    t.wait 3000

    zapp = zappa port++, ->
      @client '/index.js': ->
        @get '#/': -> alert 'hi'

    c = t.client(zapp.server)
    c.get '/index.js', (err, res) ->
      t.equal 1, res.body, ';zappa.run(function () {\n            return this.get({\n              \'#/\': function() {\n                return alert(\'hi\');\n              }\n            });\n          });'
      t.equal 2, res.headers['content-type'], JS_TYPE

  coffee: (t) ->
    t.expect 1, 2, 3, 4, 5, 6
    t.wait 10000

    zapp = zappa port++, ->
      @coffee '/coffee.js': ->
        alert 'hi'
      @coffee '/slice.js': ->
        [a,b,c...] = 'zappa,hi,zappa,here'.split ','
        alert b
      @coffee '/hasProp.js': ->
        for own k,v of a:1,b:'hi',c:3 when k is 'b'
          alert v
      @coffee '/modulo.js': ->
        a = 8 %% 5
        alert a

    c = t.client(zapp.server)
    c.get '/coffee.js', (err, res) ->
      sandbox =
        alert: (text) ->
          t.equal 1, text, 'hi'
      vm.runInNewContext res.body, sandbox
      t.equal 2, res.headers['content-type'], JS_TYPE

    c.get '/slice.js', (err,res) ->
      sandbox =
        alert: (text) ->
          t.equal 3, text, 'hi'
      vm.runInNewContext res.body, sandbox
      t.equal 4, res.headers['content-type'], JS_TYPE

    c.get '/hasProp.js', (err,res) ->
      sandbox =
        alert: (text) ->
          t.equal 5, text, 'hi'
      vm.runInNewContext res.body, sandbox

    c.get '/modulo.js', (err,res) ->
      sandbox =
        alert: (text) ->
          t.equal 6, text, 3
      vm.runInNewContext res.body, sandbox

  js: (t) ->
    t.expect 1, 2
    t.wait 3000

    zapp = zappa port++, ->
      @js '/js.js': '''
        alert('hi');
      '''

    c = t.client(zapp.server)
    c.get '/js.js', (err, res) ->
      t.equal 1, res.body, "alert('hi');"
      t.equal 2, res.headers['content-type'], JS_TYPE

  css: (t) ->
    t.expect 1, 2
    t.wait 3000

    zapp = zappa port++, ->
      @css '/index.css': '''
        body { font-family: sans-serif; }
      '''

    c = t.client(zapp.server)
    c.get '/index.css', (err, res) ->
      t.equal 1, res.body, 'body { font-family: sans-serif; }'
      t.equal 2, res.headers['content-type'], CSS_TYPE

  coffee_css: (t) ->
    t.expect 1, 2
    t.wait 3000

    zapp = zappa port++, ->
      border_radius = (radius)->
        WebkitBorderRadius: radius
        MozBorderRadius: radius
        borderRadius: radius

      @css '/index.css':
        body:
          font: '12px Helvetica, Arial, sans-serif'

        'a.button':
          border_radius '5px'

    c = t.client(zapp.server)
    c.get '/index.css', (err, res) ->
      t.equal 1, res.body, '''
        body {
            font: 12px Helvetica, Arial, sans-serif;
        }
        a.button {
            -webkit-border-radius: 5px;
            -moz-border-radius: 5px;
            border-radius: 5px;
        }
      '''
      t.equal 2, res.headers['content-type'], CSS_TYPE

  stylus: (t) ->
    t.expect 'header', 'body'
    t.wait 3000

    zapp = zappa port++, ->
      @with css:'stylus'
      @stylus '/index.css': '''
        border-radius()
          -webkit-border-radius arguments
          -moz-border-radius arguments
          border-radius arguments

        body
          font 12px Helvetica, Arial, sans-serif

        a.button
          border-radius 5px
      '''

    c = t.client(zapp.server)
    c.get '/index.css', (err, res) ->
      t.equal 'header', res.headers['content-type'], CSS_TYPE
      t.equal 'body', res.body, '''
        body {
          font: 12px Helvetica, Arial, sans-serif;
        }
        a.button {
          -webkit-border-radius: 5px;
          -moz-border-radius: 5px;
          border-radius: 5px;
        }

      '''

  less: (t) ->
    t.expect 'header', 'body'
    t.wait 3000

    zapp = zappa port++, ->
      @with css:'less'
      @less '/index.css': '''
        .border-radius(@radius) {
          -webkit-border-radius: @radius;
          -moz-border-radius: @radius;
          border-radius: @radius;
        }

        body {
          font: 12px Helvetica, Arial, sans-serif;
        }

        a.button {
          .border-radius(5px);
        }
      '''

    c = t.client(zapp.server)
    c.get '/index.css', (err, res) ->
      t.equal 'header', res.headers['content-type'], CSS_TYPE
      t.equal 'body', res.body, '''
        body {
          font: 12px Helvetica, Arial, sans-serif;
        }
        a.button {
          -webkit-border-radius: 5px;
          -moz-border-radius: 5px;
          border-radius: 5px;
        }

      '''

  'socket.io': (t) ->
    t.expect 'content-type', 'body-length'
    t.wait 3000

    zapp = zappa port++, ->

    c = t.client(zapp.server)
    c.get '/socket.io/socket.io.js', (err, res) ->
      t.equal 'content-type', res.headers['content-type'], 'application/javascript'
      t.equal 'body-length', res.body.length, 174046

 zappa_prefix: (t) ->
    t.expect 1, 2, 3
    t.wait 3000

    zapp = zappa port++, ->
      @set zappa_prefix: '/myapp/zappa'

  'socket.io_path': (t) ->
    t.expect 'content-type', 'body-length'
    t.wait 3000

    zapp = zappa port++, io:{path:'/myapp/socket.io'}, ->

    c = t.client(zapp.server)
    c.get '/myapp/socket.io/socket.io.js', (err, res) ->
      t.equal 'content-type', res.headers['content-type'], 'application/javascript'
      t.equal 'body-length', res.body.length, 174046

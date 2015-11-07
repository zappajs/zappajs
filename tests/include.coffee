zappa = require '../src/zappa'
port = 15400

JS_TYPE = 'application/javascript; charset=utf-8'

@tests =
  client: (t) ->
    t.expect 1, 2
    t.wait 3000

    zapp = zappa port++, ->
      @include './included.coffee'

    c = t.client(zapp.server)
    c.get '/index.js', (err, res) ->
      t.equal 1, res.body, ';zappa.run(function () {\n        return this.get({\n          \'#/\': function() {\n            return alert(\'hi\');\n          }\n        });\n      });'
      t.equal 2, res.headers['content-type'], JS_TYPE

  arguments: (t) ->
    t.expect 1
    t.wait 3000

    zapp = zappa port++, ->
      @include './included.coffee', a:4

    c = t.client(zapp.server)
    c.get '/foo', (err, res) ->
      t.equal 1, res.body, '{"a":4}'
      t.equal 2, res.headers['content-type'], 'application/json; charset=utf-8'

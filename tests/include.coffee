zappa = require '../src/zappa'
port = 15400

JS_TYPE = 'application/javascript; charset=utf-8'

@tests =
  client: (t) ->
    t.expect 1, 2, 3, 4, 5
    t.wait 3000

    zapp = zappa port++, ->
      @include './included.coffee'

    c = t.client(zapp.server)
    c.get '/index.js', (err, res) ->
      t.equal 1, res.body, ';zappa.run(function () {\n        return this.get({\n          \'#/\': function() {\n            return alert(\'hi\');\n          }\n        });\n      });'
      t.equal 2, res.headers['content-type'], JS_TYPE
    c.get '/zappa/zappa.js', (err, res) ->
      t.equal 3, res.headers['content-type'], JS_TYPE
    c.get '/zappa/jquery.js', (err, res) ->
      t.equal 4, res.headers['content-type'], JS_TYPE
    c.get '/zappa/sammy.js', (err, res) ->
      t.equal 5, res.headers['content-type'], JS_TYPE

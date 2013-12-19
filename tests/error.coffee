zappa = require '../src/zappa'
port = 16100

@tests =
  'error handler': (t) ->
    t.expect 'error handler returns 501', 'error handler logs'
    t.wait 3000

    zapp = zappa port++, ->
      @use @error ->
        @send 501, stack:@error.stack

      @get '/', ->
        @send @req.foo.bar

    c = t.client(zapp.server)
    c.get '/', (err, res) ->
      console.dir res.body
      t.ok 'error handler returns 501', res.statusCode is 501
      t.ok 'error handler logs', res.body.match /^TypeError: Cannot read property 'bar' of undefined/

zappa = require '../src/zappa'
port = 15300

@tests =
  # Test for express app.param
  param: (t) ->
    t.expect 1,2,3,4,5,6
    t.wait 4000
    zapp = zappa port++, ->

      @param 'user_id': ->
        if not @param.match /^[0-9A-F]{24,24}$/i
          @next new Error "Invalid user_id"
        else @next()

      @param
        'user': ->
          if not @param.match /^[0-9A-F]{24,24}$/i
            @next new Error "Invalid user"
          else @next()
        'camper': ->
          if not @param.match /^[0-9A-F]{24,24}$/i
            @next new Error "Invalid camper"
          else @next()

      @get '/:user_id', ->
        @send @params.user_id

      @get '/camper/:camper', ->
        @send @params.camper

      @get '/user/:user', ->
        @send @params.user

    c = t.client(zapp.server)
    c.get '/no-such-user-id', (err, res) ->
      t.ok 1, res.body.match /Invalid user_id/

    c.get '/123456789012345678901234', (err, res) ->
      t.equal 2, res.body, '123456789012345678901234'

    c.get '/camper/no-such-user-id', (err, res) ->
      t.ok 3, res.body.match /Invalid camper/

    c.get '/camper/123456789012345678901234', (err, res) ->
      t.equal 4, res.body, '123456789012345678901234'

    c.get '/user/no-such-user-id', (err, res) ->
      t.ok 5, res.body.match /Invalid user/

    c.get '/user/123456789012345678901234', (err, res) ->
      t.equal 6, res.body, '123456789012345678901234'

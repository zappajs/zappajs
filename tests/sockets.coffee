zappa = require '../src/zappa'
port = 15700

@tests =
  connects: (t) ->
    t.expect 1
    t.wait 3000

    zapp = zappa port++, ->
      @on connection: ->
        t.reached 1

    c = t.client(zapp.server)
    c.connect()

  'supports global middleware': (t) ->
    t.expect 1, 2
    t.wait 3000

    zapp = zappa port++, ->
      @io_use @wrap ->
        @res.locals.hello = 'bear'
        @next()
      @on connection: ->
        t.equal 1, @res.locals.hello, 'bear'
        @emit 'welcome'
      @on welcome: ->
        t.equal 2, @res.locals.hello, 'bear'

    c = t.client(zapp.server)
    c.connect()
    c.on 'welcome', ->
      c.emit 'welcome'

  'supports event middleware': (t) ->
    t.expect 1, 2, 3, 4, 5, 6
    t.wait 3000

    zapp = zappa port++, ->
      f1 = @wrap ->
        @res.locals.hello = 'bear'
        @next()
      f2 = @wrap ->
        @res.locals.hello = @data ? 'none'
        @next()
      @on 'connection', f1, ->
        t.equal 1, @res.locals.hello, 'bear'
        @emit 'welcome'
      @on 'welcome', f1, ->
        t.equal 2, @res.locals.hello, 'bear'
      @on 'connection', [f2], ->
        t.equal 3, @res.locals.hello, 'none'
      @on welcome: [f2, ->
        t.equal 4, @res.locals.hello, 'cat'
      ]
      @on 'connection', f1, f2, ->
        t.equal 5, @res.locals.hello, 'none'
      @on 'welcome', f1, f2, ->
        t.equal 6, @res.locals.hello, 'cat'

    c = t.client(zapp.server)
    c.connect()
    c.on 'welcome', ->
      c.emit 'welcome', 'cat'

  'server emits': (t) ->
    t.expect 1
    t.wait 3000

    zapp = zappa port++, ->
      @on connection: ->
        @emit 'welcome'

    setTimeout ->
      c = t.client(zapp.server)
      c.connect()

      c.on 'welcome', ->
        t.reached 1
    , 1000

  'server broadcasts': (t) ->
    t.expect 'reached1', 'reached2', 'data1', 'data2'
    t.wait 10000

    zapp = zappa port++, ->
      @on shout: ->
        @broadcast 'shouted', @data

    c = t.client(zapp.server)
    c.connect()
    c2 = t.client(zapp.server)
    c2.connect()
    c3 = t.client(zapp.server)
    c3.connect()

    c2.on 'shouted', (data) ->
      t.reached 'reached1'
      t.equal 'data1', data.foo, 'bar'

    c3.on 'shouted', (data) ->
      t.reached 'reached2'
      t.equal 'data2', data.foo, 'bar'

    c.emit 'shout', foo: 'bar'

  'server ack': (t) ->
    t.expect 'got-foo', 'acked', 'data'
    t.wait 10000

    zapp = zappa port++, ->
      @on foo: ->
        t.reached 'got-foo'
        @ack foo:'bar'

    c = t.client(zapp.server)
    c.connect()

    c.emit 'foo', bar:'foo', (data) ->
      t.reached 'acked'
      t.equal 'data', data.foo, 'bar'

  'client ack': (t) ->
    t.expect 'got-foo', 'acked', 'data'
    t.wait 10000

    zapp = zappa port++, ->
      @on connection: ->
        @emit 'foo', bar:'foo', (data) ->
          t.reached 'acked'
          t.equal 'data', data.foo, 'bar'

    c = t.client(zapp.server)
    c.connect()

    c.on 'foo', (data,ack) ->
      t.reached 'got-foo'
      ack foo:'bar'

  'server rooms': (t) ->
    t.expect 'joined1', 'room1', 'joined2', 'room2',
      'reached1', 'reached2', 'data1', 'data2'
    t.wait 10000

    zapp = zappa port++, ->
      @on join: ->
        @leave(@client.room) if @client.room
        @client.room = @data.room
        @join @data.room
        @emit 'joined', room:@data.room
      @on said: ->
        @broadcast_to @client.room, 'said', @data

    c = t.client(zapp.server)
    c.connect()
    c2 = t.client(zapp.server)
    c2.connect()

    c.on 'joined', (data) ->
      t.reached 'joined1'
      t.equal 'room1', data.room, 'main'
      c.emit 'said', msg:'done'

    c2.on 'joined', (data) ->
      t.reached 'joined2'
      t.equal 'room2', data.room, 'main'

    c.on 'said', (data) ->
      t.reached 'reached1'
      t.equal 'data1', data.msg, 'done'

    c2.on 'said', (data) ->
      t.reached 'reached2'
      t.equal 'data2', data.msg, 'done'

    c.emit 'join', room:'main'
    c2.emit 'join', room:'main'

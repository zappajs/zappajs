    pkg = require '../../package.json'
    debug = (require 'debug') "#{pkg.name}:test:connection-redis"

You need a redis server running on localhost on port 6379 to test this.
For example if you have docker.io on your machine, you could do:
```
REDIS_BIND=127.0.0.1 docker run --net host shimaore/redis-server:1.2.0
```

    describe.skip 'The ZappaJS client (with connect-redis)', ->

      app = server = null
      port = 3220
      before (done) ->
        @timeout 10*1000

        Zappa = require '../..'

        the_value = Math.random()

        {app,server} = Zappa port, ->
          @with 'client'

          RedisStore = (require 'connect-redis') @session
          @use session:
            store: new RedisStore()
            secret: 'foo'
            resave: true
            saveUninitialized: true

          @use morgan:'combined'

          @get '/', ->
            debug 'server: GET /', @session.touched
            @session.touched = the_value
            @json value: @session.touched

          @get '/again', ->
            debug 'server: GET /', @session.touched
            @json value: @session.touched

          @get '/index.html', '<html><head><title>FooBar</title></head><body></body></html>'

          @on 'check', ->
            debug 'server: On check', @session.touched
            @broadcast 'checked', null if @session.touched is the_value

          @on 'set it', ->
            debug 'server: On set it'
            @broadcast 'set it', @data

          @on 'set', ->
            debug 'server: On set'
            @session.touched = @data
            @broadcast 'was set', null

          @on 'get it', ->
            debug 'server: On get it'
            @broadcast 'get it', null

          @on 'got', ->
            debug 'server: On got'
            @broadcast 'got', @data

          @on 'received', ->
            debug 'server: On received', @session
            @session.touched = @data
            @broadcast 'getit', null

          @browserify '/test.js', ->
            Debug = require 'debug'
            # Debug.enable '*'
            pkg = require '../../package.json'
            debug = Debug "#{pkg.name}:test:connection:client"

            debug 'Starting client'
            ZappaClient = require 'zappajs-client'
            debug 'Got Client'

First we let ZappaJS-client negotiate all the parameters.

            ZappaClient ->

Once everything is ready client-side (including the DOM),

              @ready ->
                debug 'Client initialized'
                return unless @settings?

we trigger the ExpressJS request to set the session variable,

                ZappaClient.request
                .get '/'
                .then =>
                  debug 'Session data initialized'

then we force the broadcast.

                  @emit 'check'

Then the test runner will ask us to

              @on 'set it', (data) ->
                debug 'On set it'
                @emit 'set', data

              @on 'get it', ->
                debug 'On get it'
                ZappaClient.request
                .get '/again'
                .then ({body:{value}}) =>
                  debug 'Got', value
                  @emit 'got', value

            debug 'Client Ready'

        debug 'Wait for ZappaJS to start.'
        server.on 'listening', ->

          debug 'And wait for browserify to finish.'
          setTimeout (-> done()), 8*1000

      after ->
        server.close()

      jsdom = require 'jsdom'

      it 'should establish the session server-side', (done) ->
        @timeout 15*1000
        debug 'Starting JSDOM'
        jsdom.env
          url: "http://127.0.0.1:#{port}/index.html"
          scripts: ["http://127.0.0.1:#{port}/test.js"]
          done: (err,window) ->
            debug "JSDOM Failed: #{err.stack ? err}" if err?
            debug 'JSDOM Done'
          virtualConsole: jsdom.createVirtualConsole().sendTo(console)

        io = require 'socket.io-client'
        socket = io "http://127.0.0.1:#{port}"
        another_value = Math.random()
        socket.on 'checked', ->
          debug 'runner: On checked -- Session data OK'
          socket.emit 'set it', another_value
        socket.on 'was set', ->
          debug 'runner: On was set'
          socket.emit 'get it', null
        socket.on 'got', (data) ->
          debug 'runner: On got', data
          done() if data is another_value

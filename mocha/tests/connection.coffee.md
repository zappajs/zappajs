    pkg = require '../../package.json'
    debug = (require 'debug') "#{pkg.name}:test:connection"
    seem = require 'seem'

    describe 'The ZappaJS client', ->

      app = server = null
      port = 3210
      before (done) ->
        @timeout 10*1000

        Zappa = require '../..'

        the_value = Math.random()

        {app,server} = Zappa port, ->
          @with 'client'

          {MemoryStore} = @session
          @use session:
            store: new MemoryStore()
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

          @get '/index.html', '<html><head><title>FooBar</title></head><body></body><script src="test.js"></html>'

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
      {JSDOM} = jsdom

      it 'should establish the session server-side', seem ->
        @timeout 15*1000

        io = require 'socket.io-client'
        socket = io "http://127.0.0.1:#{port}"
        another_value = Math.random()
        socket.on 'checked', ->
          debug 'runner: On checked -- Session data OK'
          socket.emit 'set it', another_value
        socket.on 'was set', ->
          debug 'runner: On was set'
          socket.emit 'get it', null

        result = new Promise (done) ->
          socket.on 'got', (data) ->
            debug 'runner: On got', data
            done() if data is another_value

        debug 'Starting JSDOM'
        virtualConsole = new jsdom.VirtualConsole()
        virtualConsole.sendTo console
        dom = yield JSDOM.fromURL "http://127.0.0.1:#{port}/index.html", {
          resources: 'usable'
          runScripts: 'dangerously'
          virtualConsole
        }

        result

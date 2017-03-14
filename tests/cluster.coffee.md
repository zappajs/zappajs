    zappa = require '../src/zappa'
    port = 15804

    seem = require 'seem'
    request = require 'superagent'
    assert = require 'assert'

    sleep = (timeout) ->
      new Promise (resolve) ->
        setTimeout resolve, timeout

    do ->

      ready = seem ->

        yield sleep 1000

        {text} = yield request.get "http://localhost:#{port}/"
        assert text is 'cluster'

        {text} = yield request.get "http://127.0.0.1:#{port}/"
        assert text is 'cluster'

        console.log 'Cluster test OK'

        process.exit(0)

      zappa {ready, server:'cluster', port}, ->
        @get '/': 'cluster'


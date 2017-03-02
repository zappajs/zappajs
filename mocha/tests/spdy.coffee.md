    process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0"

    request = require 'superagent'

    port = 25674

    describe 'GET /socket.io/socket.io.js', ->

      it 'http2 returns a 200 OK', (done) ->
        server  = require '../http2'
        a = port++
        server.listen a, ->
          request
          .get "https://127.0.0.1:#{a}/"
          .then (res) ->
            done new Error 'Invalid text' unless res.text is 'ok'
          .catch done

          request
          .get "https://127.0.0.1:#{a}/socket.io/socket.io.js"
          .then (res) ->
            done() if res.ok
          .catch done

      it 'spdy returns a 200 OK', (done) ->
        server  = require '../spdy'
        a = port++
        server.listen a, ->
          request
          .get "https://127.0.0.1:#{a}/"
          .then (res) ->
            done new Error 'Invalid text' unless res.text is 'ok'
          .catch done

          request
          .get "https://127.0.0.1:#{a}/socket.io/socket.io.js"
          .then (res) ->
            done() if res.ok
          .catch done

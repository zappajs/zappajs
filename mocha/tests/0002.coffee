# test.coffee for mocha
supertest = require 'supertest'

new_app = ->
  server = require('../..').app ->
    @include '../app.coffee'
  server.app

describe 'GET /health', ->

  express = new_app()

  it 'returns a 200 OK', (done) ->
    supertest(express)
    .get '/health'
    .expect 'Content-Type', /json/
    .expect 200, done

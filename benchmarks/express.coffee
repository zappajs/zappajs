app = require('express')()
fs = require 'fs'

cache = {}

app.engine '.coffee', (path,options,next) ->
  cache[path] ?= require path
  next null, cache[path] options

app.get '/', (req, res) ->
  res.render 'index.jade', foo: 'Express + Jade'

app.get '/coffeekup', (req, res) ->
  res.render 'index.coffee', foo: 'Express + CoffeeCup'

app.listen 3000

console.log "Listening on 3000..."

app = require('express')()
fs = require 'fs'

compile = require('coffeecup').adapters.express.compile
cache = {}

app.engine '.coffee', (path,options,next) ->
  cache[path] ?= compile fs.readFileSync( path, 'utf8' ), options
  next null, cache[path] options

app.get '/', (req, res) ->
  res.render 'index.jade', foo: 'Express + Jade'

app.get '/coffeekup', (req, res) ->
  res.render 'index.coffee', foo: 'Express + CoffeeCup'

app.listen 3000

console.log "Listening on 3000..."

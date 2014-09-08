# app.coffee
@include = ->

  @get '/health', ->
    @jsonp
      pid: process.pid
      memory: process.memoryUsage()
      uptime: process.uptime()

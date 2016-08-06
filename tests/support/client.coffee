log = console.log
fs = require 'fs'
url = require 'url'
request = require 'request'
jsdom = require 'jsdom'
io = require 'socket.io-client'

class Client
  constructor: (arg) ->
    if typeof arg is 'string'
      @url = arg
      @parsed = url.parse arg
      @protocol = @parsed.protocol or 'http:'
      @host = @parsed.hostname
      @port = @parsed.port or 80
    else
      @server = arg
      check = =>
        try
          @host = @server.address().address
          @port = @server.address().port
        catch err
          process.nextTick check
      check()
      if @host is '::'
        @host = '127.0.0.1'

  request: (method = 'get', args...) ->
    for k, v of args
      switch typeof v
        when 'string' then path = v
        when 'object' then opts = v
        when 'function' then cb = v

    opts ?= {}
    opts.followRedirect ?= no
    opts.jar = false
    opts.method ?= method
    {pathname,search} = url.parse path
    opts.url = url.format
      protocol: 'http:'
      hostname: @host
      port: @port
      pathname: pathname
      search: search
    console.log opts.url
    opts.encoding ?= 'utf8'

    req = request opts, (err, res) ->
      if err and cb? then cb(err)
      else
        if opts.dom?
          jsdom.env html: res.body, done: (err, window) ->
            if err and cb? then cb(err)
            else cb(null, res, window)
        else
          cb(null, res) if cb?

  get: (args...) -> @request 'get', args...
  post: (args...) -> @request 'post', args...
  put: (args...) -> @request 'put', args...
  del: (args...) -> @request 'delete', args...
  head: (args...) -> @request 'head', args...
  patch: (args...) -> @request 'patch', args...

  connect: ->
    the_url = url.format
      protocol: 'http:'
      hostname: @host
      port: @port
    console.log the_url
    @socket = io(the_url, { 'force new connection': true })

  on: -> @socket.on.apply @socket, arguments
  emit: -> @socket.emit.apply @socket, arguments

module.exports = (args...) ->
  c = new Client(args...)
  c.get.dom = (args...) ->
    for a in args
      if typeof a is 'object'
        found = yes
        a.dom = yes
    args.push dom: yes unless found
    c.get.apply c, args
  c

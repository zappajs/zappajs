http2 = require 'spdy'
fs = require 'fs'
Zappa = require './zappajs'

z = Zappa.app ->
  @use morgan: 'dev'

  @get '/', ->
    @send 'hello, http2!\ngo to /pushy'

  @get '/pushy', ->
    stream = @res.push '/main.js',
      status: 200
      method: 'GET'
      request:
        accept: '*/*'
      response:
        'content-type': 'application/javascript'
    stream.on 'error', ->
    stream.end 'alert("hello from push stream!");'
    @res.end '<script src="/main.js"></script>'

options =
  key: fs.readFileSync 'ssl/key.pem'
  cert: fs.readFileSync 'ssl/cert.pem'

http2
  .createServer(options, z.app)
  .listen 8080, =>
    console.log 'Server is listening on https://localhost:8080. You can open the URL in the browser.'

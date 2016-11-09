http2 = require 'http2'
Zappa = require '..'

key = (require 'fs').readFileSync(__dirname + '/../examples/ssl/key.pem')
cert = (require 'fs').readFileSync(__dirname + '/../examples/ssl/cert.pem')

z = Zappa.app http_module:http2, https:{key,cert}, ->
  @use morgan: 'dev'
  @get '/', ->
    @send 'ok'

module.exports = z.server

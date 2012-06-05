# Start a HTTPS server on port 3443
fs = require 'fs'
https_options =
  key: fs.readFileSync 'ssl/key.pem'
  cert: fs.readFileSync 'ssl/cert.pem'

require('./zappajs') 3443, https:https_options, ->
  @get '/': 'hi'

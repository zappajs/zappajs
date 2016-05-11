This is a modified version of [browserify-string](https://github.com/eugeneware/browserify-string).
Basically it is [pull request #5](https://github.com/eugeneware/browserify-string/pull/5/commits/a2d22314fa902897d2b05278eebdbf0b5a86f76b).

    browserify = require 'browserify'
    path = require 'path'
    {Readable} = require 'stream'

    module.exports = ( str, opts ) ->
      if typeof str is 'function'
        str = [
          '('
          str.toString()
          ')();'
        ].join '\n'

      opts.basedir ?= process.cwd()

      stream = new Readable()
      stream.push str
      stream.push null

      browserify stream, opts

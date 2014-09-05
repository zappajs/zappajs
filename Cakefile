{spawn, exec} = require 'child_process'
log = console.log

task 'build', ->
  run 'coffee -o lib -c src/*.coffee'

task 'test', ->
  # Set `ulimit -n 1024` if you run out of descriptors.
  run 'coffee tests/index.coffee'

task 'bench', ->
  run 'cd benchmarks && ./run'

task 'docs', ->
  run 'docco src/*.coffee'

task 'setup', 'build', ->
  invoke 'build'

task 'clean', ->
  run 'rm -r vendor node_modules lib/*.js benchmarks/out/*.dat benchmarks/out/*.out tests/*.js _site', ->
    run 'npm cache clear'

run = (args...) ->
  for a in args
    switch typeof a
      when 'string' then command = a
      when 'object'
        if a instanceof Array then params = a
        else options = a
      when 'function' then callback = a

  command += ' ' + params.join ' ' if params?
  cmd = spawn '/bin/sh', ['-c', command], options
  cmd.stdout.on 'data', (data) -> process.stdout.write data
  cmd.stderr.on 'data', (data) -> process.stderr.write data
  process.on 'SIGHUP', -> cmd.kill()
  cmd.on 'exit', (code) -> callback() if callback? and code is 0

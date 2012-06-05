{spawn, exec} = require 'child_process'
log = console.log
      
task 'build', ->
  run 'coffee -o lib -c src/*.coffee'
    
task 'test', ->
  run 'coffee tests/index.coffee'
    
task 'bench', ->
  run 'cd benchmarks && ./run'
    
task 'docs', ->
  run 'docco src/*.coffee'
  
task 'vendor', ->
  run 'mkdir -p vendor && cd vendor && curl -OL http://code.jquery.com/jquery-1.7.2.min.js', ->
    run 'cd vendor && curl -OL https://github.com/quirkey/sammy/raw/master/lib/min/sammy-0.7.1.min.js', ->
      run 'head -n 1 vendor/jquery*', ->
        run 'head -n 3 vendor/sammy*'

task 'setup', 'build + vendor', ->
  invoke 'build'
  invoke 'vendor'

task 'clean', ->
  run 'rm -r vendor node_modules lib/*.js benchmarks/out/*.dat benchmarks/out/*.out tests/*.js _site'

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

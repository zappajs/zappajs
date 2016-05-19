@include = (foo) ->
  @with 'client'
  @browserify '/index.js': ->
    alert 'hi'

  @get '/foo', ->
    @json foo

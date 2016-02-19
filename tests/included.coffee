@include = (foo) ->
  @browserify '/index.js': ->
    alert 'hi'

  @get '/foo', ->
    @json foo

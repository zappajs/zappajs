@include = (foo) ->
  @client '/index.js': ->
    @get '#/': -> alert 'hi'

  @get '/foo', ->
    @json foo

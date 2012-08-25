@include = ->
  @client '/index.js': ->
    @get '#/': -> alert 'hi'

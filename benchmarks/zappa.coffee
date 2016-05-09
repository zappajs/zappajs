require('../src/zappa') ->

  @get '/': ->
    @render 'index.pug', {foo: 'Zappa + pug, no layout',layout:no}

  @get '/pug': ->
    @render 'index.pug': {foo: 'Zappa + pug'}

  @get '/coffeekup': ->
    @render 'index.coffee': {foo: 'Zappa + CoffeeKup'}

  @get '/coffee': ->
    @render 'index.coffee': {foo: 'Zappa + CoffeeKup, no layout',layout:no}

  m = ->
    @next()
  @get '/middleware', m, -> 'hello'

  n = (req,res,next) ->
    next()
  @get '/middleware-native', n, -> 'hello'

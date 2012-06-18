require('../src/zappa') ->

  @get '/': ->
    @render 'index.jade', {foo: 'Zappa + Jade, no layout',layout:no}

  @get '/jade': ->
    @render 'index.jade': {foo: 'Zappa + Jade'}

  @get '/coffeekup': ->
    @render 'index.coffee': {foo: 'Zappa + CoffeeKup'}

  @get '/coffee': ->
    @render 'index.coffee': {foo: 'Zappa + CoffeeKup, no layout',layout:no}

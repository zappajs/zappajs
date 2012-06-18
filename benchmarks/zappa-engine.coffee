require('../src/zappa') ->

  z = @

  # @register '.coffee': require('coffeecup').adapters.express

  @get '/': ->
    @render 'index.jade', {foo: 'Zappa + Jade, no layout',layout:no}

  @get '/coffeekup': ->
    @render 'index.coffee': {foo: 'Zappa + CoffeeKup, no layout',layout:no}

  @get '/coffee': ->
    @render 'index.coffee', {foo: 'Zappa + CoffeeCup'}

  @get '/jade': ->
    @render 'index.jade', {foo: 'Zappa + Jade'}

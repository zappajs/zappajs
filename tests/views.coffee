zappa = require '../src/zappa'
port = 15600

@tests =
  inline: (t) ->
    t.expect 1, 2
    t.wait 3000

    zapp = zappa port++, ->
      @get '/bar': ->
        @render 'index', foo: 'bar'
      @get '/foobar': ->
        @render 'index', foo: 'foobar'

      {h2} = @teacup
      @view index: -> h2 "teacup inline template: #{@foo}"

    c = t.client(zapp.server)
    c.get '/bar', (err, res) ->
      t.equal 1, res.body, '<h2>teacup inline template: bar</h2>'
    c.get '/foobar', (err, res) ->
      t.equal 2, res.body, '<h2>teacup inline template: foobar</h2>'

  file: (t) ->
    t.expect 1
    t.wait 3000

    zapp = zappa port++, ->
      @get '/': ->
        @render 'index', foo: 'bar'

    c = t.client(zapp.server)
    c.get '/', (err, res) ->
      t.equal 1, res.body, '<h2>teacup file template: bar</h2>'

  'response.render, file': (t) ->
    t.expect 1
    t.wait 3000

    zapp = zappa port++, ->
      @get '/': ->
        @response.render 'index', foo: 'bar'

    c = t.client(zapp.server)
    c.get '/', (err, res) ->
      t.equal 1, res.body, '<h2>teacup file template: bar</h2>'

  'eco, inline': (t) ->
    t.expect 1
    t.wait 3000

    zapp = zappa port++, ->
      @app.engine 'eco', require('consolidate').eco
      @set 'view engine': 'eco'

      @get '/': ->
        @render 'index', foo: 'bar', layout: no

      @view index: "<h2>Eco inline template: <%= @foo %></h2>"

    c = t.client(zapp.server)
    c.get '/', (err, res) ->
      t.equal 1, res.body, '<h2>Eco inline template: bar</h2>'

  'eco, file': (t) ->
    t.expect 1
    t.wait 3000

    zapp = zappa port++, ->
      @app.engine 'eco', require('consolidate').eco
      @set 'view engine': 'eco'

      @get '/': ->
        @render 'index', foo: 'bar'

    c = t.client(zapp.server)
    c.get '/', (err, res) ->
      t.equal 1, res.body, '<h2>Eco file template: bar</h2>'

  'jade, inline': (t) ->
    t.expect 1
    t.wait 3000

    zapp = zappa port++, ->
      @set 'view engine': 'jade'

      @get '/': ->
        @render 'index', foo: 'bar', layout: no

      @view index: "h2= 'Jade inline template: ' + foo"

    c = t.client(zapp.server)
    c.get '/', (err, res) ->
      t.equal 1, res.body, '<h2>Jade inline template: bar</h2>'

  'jade, inline + include': (t) ->
    t.expect 1
    t.wait 3000

    zapp = zappa port++, ->
      @set 'view engine': 'jade'
      @engine 'jade zappa': (template,options,path) ->
        options.filename = path
        (require 'jade').render template, options

      @get '/': ->
        @render 'index', foo: 'bar'

      @view index: '''
        doctype html
        html
          include head
          body
            h2= 'Jade inline template: ' + foo
            include foot
      '''

    c = t.client(zapp.server)
    c.get '/', (err, res) ->
      t.equal 1, res.body, '<!DOCTYPE html><html><head><title>Jade file header</title></head><body><h2>Jade inline template: bar</h2><div>This was an example.</div></body></html>'

  'jade, file': (t) ->
    t.expect 1
    t.wait 3000

    zapp = zappa port++, ->
      @set 'view engine': 'jade'

      @get '/': ->
        @render 'index', foo: 'bar'

    c = t.client(zapp.server)
    c.get '/', (err, res) ->
      t.equal 1, res.body, '<h2>Jade file template: bar</h2>'

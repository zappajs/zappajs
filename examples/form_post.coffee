# This example shows how to use the default layout to render
# a form and retrieve data from its submission.

require('./zappajs') ->
  @enable 'default layout'
  @use 'bodyParser'

  @get '/': ->
    @render index: {}

  @post '/widgets': ->
    @render widgets: { form: @body }

  @view index: ->
    @title = 'My Form'
    h1 @title
    form method: 'post', action: '/widgets', ->
      input
        id: 'widget_name'
        type: 'text'
        name: 'widget_name'
        placeholder: 'widget name'
        size: 50
        value: @widget_name
      button 'create widget'

  @view widgets: ->
    @title = 'Widgets'
    h1 @title
    p @form.widget_name

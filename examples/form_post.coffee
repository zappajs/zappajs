# This example shows how to use the default layout to render
# a form and retrieve data from its submission.

require('./zappajs') ->
  @use (require 'body-parser').urlencoded()

  @locals.title = 'My App'

  @get '/': ->
    @render index: {}

  @post '/widgets': ->
    @locals.title = 'My Widget'
    @render widgets: { form: @body }

  {form,input,button,h1,p} = @teacup

  # Teacup expects template parameters as argument;
  # for inline views, ZappaJS extends this to allow parameters in the template scope.
  # (This is currently not available for views in files, because those are managed
  # by Express, not by Zappa.)

  # This function uses Teacup's normal behavior.

  @view index: ({title,widget_name}) ->
    h1 title
    form method: 'post', action: '/widgets', ->
      input '#widget_name',
        type: 'text'
        name: 'widget_name'
        placeholder: 'widget name'
        size: 50
        value: widget_name
      button 'create widget'

  # This function shows ZappaJS' scope change.

  @view widgets: ->
    h1 @title
    for name in @form.widget_name.split /\s+/
      p name

  # Obviously you can mix & match both ways.

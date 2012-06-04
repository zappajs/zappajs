# connect-assets example

# First version, using views/assets.coffee

require('./zappajs') 3000, ->

  assets = require 'connect-assets'
  @use assets
    src: './public'
    build: true
    buildDir: 'public/bin'
    minifyBuilds: false
    # `css`, `img`, and `js` are added to the global scope.

  @get '/', ->
    @render 'assets', layout:no

# Second version, using @view and no pollution of the global scope.

require('zappajs') 3001, ->

  render_context =
    layout: no

  assets = require 'connect-assets'
  @use assets
    src: './public'
    build: true
    buildDir: './public/bin'
    minifyBuilds: false
    helperContext: render_context

  @view index: ->
    html ->
      head ->
        # public/app.coffee dynamically built by connect-assets
        text @js 'app'
      body ->
        @body

  @get '/': ->
    # Note: this does not work with `hardcode` (Coffee[CK]up limitation).
    @render 'index', render_context

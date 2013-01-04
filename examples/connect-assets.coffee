# connect-assets examples
# =======================

# Overview
# --------

# The simplest usage pattern for connect-assets would be:
#
#   assets = require 'connect-assets'
#   @use assets()
#
# However the defaults for connect-assets are different from
# those used by Express and Zappa: for example the assets files
# connect-assets are looked up in directory `./assets/` instead
# of `./public/` in Express views.
# The following two examples show how to use `connect-assets` in
# a way consistent with Express and Zappa conventions.
#
# See also https://github.com/TrevorBurnham/connect-assets
# and the example in the ./more_assets/ directory.

# How this works
# --------------

# In the following two examples, the view contains code similar to:
#
#   html ->
#     head ->
#       text js 'app'
#
# The source code for `app` is found in ./public/js/app.coffe and
# will in turn include ./public/js/dep.coffee and the content of
# the ./public/js/vendors/ subtree. The `js` function is provided
# by `connect-assets`.

# First example
# -------------

# This first version uses the file ./views/assets.coffee as the
# source for the view.
#
# The drawback of this solution is that functions `css`, `img`, and
# `js` are added to the global scope, which is generally considered
# bad coding practices.

require('./zappajs') 3000, ->

  assets = require 'connect-assets'
  @use assets
    src: './public'
    build: true
    buildDir: 'public/bin'
    minifyBuilds: false

  @get '/', ->
    @render 'assets', layout:no

# Second example
# --------------

# This second version uses ZappaJS' `@view` and injects the `css`,
# `img`, and `js` functions via the `render_context` object, which
# prevents pollution of the global scope.

require('./zappajs') 3001, ->

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

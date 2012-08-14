# A more complex example showing both `require`
# and `require_tree` provided by `connect-assets`
# in CoffeeScript files.
#
# Add
#
#     text js 'app'
#
# in your layout template to include this script
# and all its dependencies as a single file.

# Vendor
#= require 'vendor/jquery.js'
#= require 'vendor/underscore.js'
#= require 'vendor/backbone.js'
#= require 'vendor/backbone.queryparams.js'
#= require 'vendor/bootstrap.js'
#= require 'vendor/jquery.history.js'
#= require 'vendor/jquery.transit.js'
#= require 'vendor/highcharts.src.js'
#= require 'vendor/swfobject.js'

# Application
#= require 'init'
#= require_tree 'helpers'
#= require_tree 'templates'
#= require_tree 'views'
#= require 'router'
#= require 'main'

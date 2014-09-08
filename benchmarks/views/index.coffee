{renderable,h2} = require 'teacup'
module.exports = renderable ({foo}) ->
  h2 'teacup file template'
  p foo

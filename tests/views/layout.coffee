{doctype,html,head,title,body} = require 'teacup'
module.exports = ->
  doctype 5
  html ->
    head ->
      title 'CoffeeKup file layout'
    body @body

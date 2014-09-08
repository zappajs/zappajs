{renderable,doctype,html,head,title,body,h1} = @teacup
module.exports = renderable (opts) ->
  doctype 5
  html ->
    head ->
      title 'CoffeeKup file layout'
    body ->
      h1 'CoffeeKup file layout'
      opts.body

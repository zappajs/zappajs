    module.exports = ({context}) ->
      {app} = context

On `__zappa_settings`
---------------------

The special event `__zappa_settings` is used by the client to request that the current application settings be sent back.

      context.on '__zappa_settings', (data,ack) ->
        unless ack?
          debug 'Client did not request `ack` for __zappa_settings'
          return
        ack app.settings

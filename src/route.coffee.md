route
=====

    invariate = require 'invariate'

Register a route with express.

    module.exports = ({context,apply_helpers,seemify}) ->

      {app,zappa,io} = context

      route = (r) ->
        r.middleware ?= []

        if typeof r.handler is 'string'
          app[r.verb] r.path, r.middleware, (req, res) ->
            res.type r.type if r.type?
            res.send r.handler
            return
        else if r.handler.call?

          app[r.verb] r.path, r.middleware, (req, res, next) ->

Context available inside the `get`, ... handlers.

            socket_id = req.session?.__socket?[app.settings.zappa_channel]?.id

            ctx =
              app: app
              io: io
              settings: app.settings
              locals: res.locals
              id: socket_id

              ## socket
              ## client

              request: req
              req: req
              query: req.query
              params: req.params
              body: req.body
              session: req.session
              response: res
              res: res
              next: next
              send: -> res.send.apply res, arguments
              json: -> res.json.apply res, arguments
              jsonp: -> res.jsonp.apply res, arguments
              redirect: -> res.redirect.apply res, arguments
              format: -> res.format.apply res, arguments

FIXME: Study render specifications for ExpressJS (esp. since async is becoming the only supported method) and adjust here, using `invariate` if that makes sense.

              render: ->
                if typeof arguments[0] isnt 'object'
                  render.apply @, arguments
                else
                  for k, v of arguments[0]
                    render.apply @, [k, v]
                return

              ## join
              ## leave

              emit: invariate.acked (k,v,ack) ->
                if socket_id?
                  room = io.in socket_id
                  room.emit.call room, k, v, (ack_data) ->
                    ack_ctx = build_ctx
                      event: k
                      data: ack_data
                    seemify ack, ack_ctx, arguments
                return

              broadcast_to: (room, args...) ->
                room = io.to room
                broadcast = invariate (k,v) ->
                  room.emit.call room, k, v
                broadcast args...
                return


            build_ctx = (o) ->
              _ctx = {}
              _ctx[k] = v for own k,v of ctx
              if o?
                _ctx[k] = v for own k,v of o
              _ctx

            render = (name,opts = {},fn) ->

              report = fn ? (err,html) ->
                if err
                  next err
                else
                  res.send html

              # Make sure the second arg is an object.
              if typeof opts is 'function'
                fn = opts
                opts = {}

              res.render.call res, name, opts, report

            finalize = (value) ->
              res.type(r.type) if r.type?
              if typeof value is 'string'
                res.send value
              else
                value

            apply_helpers ctx

            if app.settings['x-powered-by']
              res.setHeader 'X-Powered-By', "Zappa #{zappa.version}"

            result = seemify r.handler, ctx, [req, res, next]

A generator function will return an Object. Assume that object returns a Promise (as in `co` or `seem`).
We can then handle the Promise.

            if typeof result?.then is 'function'
              result.then finalize, next
            else
              finalize result

        else
          throw new Error "ZappaJS invalid handler of type #{typeof r.handler}: #{util.inspect r.handler}"

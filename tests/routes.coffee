zappa = require '../src/zappa'
port = 15000

@tests =
  hello: (t) ->
    t.expect 1, 2, 3, 4, 5
    t.wait 3000

    zapp = zappa port++, ->
      @get '/string': 'string'
      @get '/return': -> 'return'
      @get '/send': -> @send 'send'
      @get /\/regex$/, 'regex'
      @get /\/regex_function$/, -> 'regex function'

    c = t.client(zapp.server)
    c.get '/string', (err, res) -> t.equal 1, res.body, 'string'
    c.get '/return', (err, res) -> t.equal 2, res.body, 'return'
    c.get '/send', (err, res) -> t.equal 3, res.body, 'send'
    c.get '/regex', (err, res) -> t.equal 4, res.body, 'regex'
    c.get '/regex_function', (err, res) -> t.equal 5, res.body, 'regex function'

  verbs: (t) ->
    t.expect 1, 2, 3
    t.wait 3000

    zapp = zappa port++, ->
      @post '/': -> 'post'
      @put '/': -> 'put'
      @delete '/': -> 'delete'

    c = t.client(zapp.server)
    c.post '/', (err, res) -> t.equal 1, res.body, 'post'
    c.put '/', (err, res) -> t.equal 2, res.body, 'put'
    c.del '/', (err, res) -> t.equal 3, res.body, 'delete'

  redirect: (t) ->
    t.expect 1, 2
    t.wait 3000

    zapp = zappa port++, ->
      @get '/': -> @redirect '/foo'

    c = t.client(zapp.server)
    c.get '/', (err, res) ->
      t.equal 1, res.statusCode, 302
      t.ok 2, res.headers.location.match /\/foo$/

  params: (t) ->
    t.expect 1, 2
    t.wait 3000

    zapp = zappa port++, ->
      @use (require 'body-parser').urlencoded extended:false
      @get '/:foo': -> @params.foo + @query.ping
      @post '/:foo': -> @params.foo + @query.ping + @body.zig

    c = t.client(zapp.server)

    c.get '/bar?ping=pong', (err, res) ->
      t.equal 1, res.body, 'barpong'

    headers = 'Content-Type': 'application/x-www-form-urlencoded'
    form = {zig: 'zag'}
    c.post '/bar?ping=pong', {headers, form}, (err, res) ->
      t.equal 2, res.body, 'barpongzag'

  middleware: (t) ->
    t.expect 1, 2, 3
    t.wait 3000

    zapp = zappa port++, ->

      users =
        bob: 'bob user'

      load_user = @wrap ->
        user = users[@params.id]
        if user
          @locals.user = user
          @next()
        else
          @next new Error "Failed to load user #{@params.id}"

      @get '/string/:id', load_user, -> 'string'
      @get '/return/:id', load_user, -> 'return'
      @get '/send/:id', load_user, -> @send 'send'

      @get '/string1/:id': [load_user, -> 'string']
      @get '/return1/:id': [load_user, -> 'return']
      @get '/send1/:id': [load_user, -> @send 'send']

    c = t.client(zapp.server)
    c.get '/string/bob', (err, res) -> t.equal 1, res.body, 'string'
    c.get '/return/bob', (err, res) -> t.equal 2, res.body, 'return'
    c.get '/send/bob', (err, res) -> t.equal 3, res.body, 'send'
    c.get '/send/bar', (err, res) -> t.ok 3, res.body.match /Failed to load user bar/

    c.get '/string1/bob', (err, res) -> t.equal 1, res.body, 'string'
    c.get '/return1/bob', (err, res) -> t.equal 2, res.body, 'return'
    c.get '/send1/bob', (err, res) -> t.equal 3, res.body, 'send'
    c.get '/send1/bar', (err, res) -> t.ok 3, res.body.match /Failed to load user bar/

  methods: (t) ->
    t.expect [1..6]...
    t.wait 3000

    zapp = zappa port++, ->

      @get '/', -> @send 'got'
      @post '/', -> @send 'posted'
      @put '/', -> @send 'put'
      @delete '/', -> @send 'deleted'
      @head '/', -> @send 'head'
      @patch '/', -> @send 'patched'

    c = t.client zapp.server
    c.get '/', (err,res) -> t.equal 1, res.body, 'got'
    c.post '/', (err,res) -> t.equal 2, res.body, 'posted'
    c.put '/', (err,res) -> t.equal 3, res.body, 'put'
    c.del '/', (err,res) -> t.equal 4, res.body, 'deleted'
    # c.head '/', (err,res) -> t.equal 5, res.body, undefined
    c.head '/', (err,res) -> t.equal 5, res.body, ''
    c.patch '/', (err,res) -> t.equal 6, res.body, 'patched'

  generators: (t) ->
    t.expect 1, 2, 3, 4
    t.wait 3000

    zapp = zappa port++, ->

      @get '/', -> yield @send 'got'
      @get '/:name', -> yield @send @params.name

    c = t.client zapp.server
    c.get '/', (err,res) -> t.equal 1, res.body, 'got'
    c.get '/', (err,res) -> t.equal 2, res.body, 'got'
    c.get '/foo', (err,res) -> t.equal 3, res.body, 'foo'
    c.get '/bar', (err,res) -> t.equal 4, res.body, 'bar'

  json: (t) ->
    t.expect 2
    t.wait 3000

    zapp = zappa port++, ->

      @get '/', -> @json {attr1: 'attr1', attr2: 'attr2'}

    c = t.client zapp.server
    c.get '/', (err, res) ->
        t.equal 1, res.headers['content-type'], 'application/json; charset=utf-8'
        t.equal 2, res.body, '{"attr1":"attr1","attr2":"attr2"}'

  jsonp: (t) ->
    t.expect 2
    t.wait 3000

    zapp = zappa port++, ->

      @get '/', -> @jsonp {attr1: 'attr1', attr2: 'attr2'}

    c = t.client zapp.server
    c.get '/?callback=foo', (err, res) ->
        t.equal 1, res.headers['content-type'], 'text/javascript; charset=utf-8'
        t.equal 2, res.body, '/**/ typeof foo === \'function\' && foo({"attr1":"attr1","attr2":"attr2"});'

  'jsonp + custom callback': (t) ->
    t.expect 2
    t.wait 3000

    zapp = zappa port++, ->

      @set 'jsonp callback name': 'cb'
      @get '/', -> @jsonp {attr1: 'attr1', attr2: 'attr2'}

    c = t.client zapp.server
    c.get '/?cb=foo', (err, res) ->
        t.equal 1, res.headers['content-type'], 'text/javascript; charset=utf-8'
        t.equal 2, res.body, '/**/ typeof foo === \'function\' && foo({"attr1":"attr1","attr2":"attr2"});'

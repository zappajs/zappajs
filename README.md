Zappa is a [CoffeeScript](http://coffeescript.org)-optimized interface to [Express](http://expressjs.com) and [Socket.IO](http://socket.io).

[![Build Status](https://secure.travis-ci.org/zappajs/zappajs.png?branch=4.x)](http://travis-ci.org/zappajs/zappajs) [![Dependency Status](https://gemnasium.com/zappajs/zappajs.png)](https://gemnasium.com/zappajs/zappajs)

## Synopsis

```coffee
require('zappajs') ->

  ## Server-side ##
  teacup = @teacup

  @get '/': ->
    @render 'index',
      title: 'Zappa!'
      scripts: '/zappa/full.js /index.js /client.js'
      stylesheet: '/index.css'

  @view index: ->
    {doctype,html,head,title,script,link,body,h1,div} = teacup
    doctype 5
    html =>
      head =>
        title @title if @title
        for s in @scripts.split ' '
          script src: s
        link rel:'stylesheet', href:@stylesheet
      body ->
        h1 'Welcome to Zappa!'
        div id:'content'

  pixels = 12

  @css '/index.css':
    body:
      font: '12px Helvetica'
    h1:
      color: 'pink'
      height: "#{pixels}px"

  @get '/:name/data.json': ->
    record =
      id: 123
      name: @params.name
      email: "#{@params.name}@example.com"
    @json record

  @on 'ready': ->
    console.log "Client #{@id} is ready and says #{@data}."

  ## Client-side ##

  @coffee '/index.js': ->
    alert 'hi'

  @browserify '/client.js': ->
    ZappaClient = require 'zappajs-client'

    ZappaClient ->
      @ready ->
        @emit 'ready', 'hello'
```

## Install

    npm install zappajs

## Other resources

- The source code [repository](http://github.com/zappajs/zappajs) at github

- Questions, suggestions? Drop us a line on the [mailing list](http://groups.google.com/group/zappajs)

- Found a bug? Open an [issue](http://github.com/zappajs/zappajs/issues) at github

## ZappaJS 4.0 Changes

### Major improvements in Socket.IO interface:

Now supports saving the Session object in Socket.IO methods. Session content can be modified both from ExpressJS and from Socket.IO.

Supports `ack` callback for all Socket.IO `emit` calls.

### Removal of embedded client-side code:

The ZappaJS client is no longer embedded and was moved to a separate module, [`zappajs-client`](https://github.com/zappajs/zappajs-client).

Sammy and jQuery are no longer embedded:
- As a consequence the `zappa` middleware is no longer required and was removed. If your code references any Javascript file under `/zappa/`, consider using e.g. `browserify-middleware` to build the dependencies.
- Also, `@client` and `@shared` are gone (along with their magic).

Client-side code is now bundled using `browserify-string`; `@browserify` replaces `@client`, while `@isomorph` replaces `@shared`.

### New features

Now uses the `debug` module instead of logging to console directly.

Host and port might be specified using the `ZAPPA_PORT` and `ZAPPA_HOST` environment variables, which are used as default if no explicit configuration is provided.

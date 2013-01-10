---
layout: default
title: How to Test Zappa(JS) Apps
---

# {{page.title}}

## Introduction

In this document we describe how to modify the following, typical Zappa(JS) code in order to make it easier to test.

    require('zappajs') 2222, ->

      @get '/health', ->
        @jsonp
          pid: process.pid
          memory: process.memoryUsage()
          uptime: process.uptime()

## First Approach: Using `@include`

You can break down a large Zappa application into smaller bits by using `@include`. This allows you to build large Zappa applications by combining reusable, smaller, domain-specific applications.

Moreover, `@include` can be used to split the code that starts the application (the web server) and the application logic itself, as follows.

### A Simple Server

The server is a two-line script in our case:

    # server.coffee
    module.exports = require('zappajs') 2222, ->
      @include './app.coffee'

If you want to integrate the server with clustering or `forever`, this would be a good place to add these.

### The Application

The application itself is written in a separate file.

    # app.coffee
    @include = ->

      @get '/health', ->
        @jsonp
          pid: process.pid
          memory: process.memoryUsage()
          uptime: process.uptime()

### Testing the Application

You can now test the application without actually starting a web server. For example using `mocha`:

    # test.coffee
    server  = require('zappajs').app ->
      @include './app.coffee'
    express = server.app

    supertest = require 'supertest'
    mocha = require 'mocha'

    describe 'GET /health', ->

      it 'returns a 200 OK', (done) ->
        supertest(express)
          .get('/health')
          .expect('Content-Type', /json/)
          .expect(200,done)

Note how the application is started using `zappajs.app`, which creates a Node.js server but does not bind it to a specific port.

Run `coffee -c test.coffee` then `mocha test.coffee` to confirm the application works as expected.

If you need to make sure the test uses a brand new server each time, move the server creation code inside the tests:

    # test.coffee
    supertest = require 'supertest'
    mocha = require 'mocha'

    describe 'GET /health', ->

      server    = require('zappajs').app ->
        @include './app.coffee'
      express = server.app

      it 'returns a 200 OK', (done) ->
        supertest(express)
          .get('/health')
          .expect('Content-Type', /json/)
          .expect(200,done)

## Second Approach: Turn Your Application into a Module. Or a Server.

In this second approach, a single source file is used. If it is the main module it then starts a server; whereas if it is used by another module it doesn't.

    # server.coffee
    app = require('zappajs').app ->

      @get '/health', ->
        @jsonp
          pid: process.pid
          memory: process.memoryUsage()
          uptime: process.uptime()

    if require.main is module
      # Running as an application, start the server
      app.server.listen 2222
    else
      # Only testing
      modules.export = app

In this case the test application then becomes:

    # test.coffee
    server  = require './server'
    express = server.app

    supertest = require 'supertest'
    mocha = require 'mocha'

    describe 'GET /health', ->

      it 'returns a 200 OK', (done) ->
        supertest(express)
          .get('/health')
          .expect('Content-Type', /json/)
          .expect(200,done)

However this method might not work well if `server.coffee` is ran as a module, for example when using `forever`. In that later case the automagic module-vs-server detection would fail.
The first approach offered above (using `@include`) is recommended to avoid these issues, since it clearly delineates the server and the application.

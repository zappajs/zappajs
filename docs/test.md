---
layout: default
title: How to Test Zappa(JS) Apps
---

# {{page.title}}

## Introduction

In this document we describe how to refactor the following, typical Zappa(JS) code in order to make it easier to test.

    require('zappajs') 2222, ->

      @get '/health', ->
        @jsonp
          pid: process.pid
          memory: process.memoryUsage()
          uptime: process.uptime()

### Use `@include`

You can break down a large Zappa application into smaller bits by using `@include`. This allows you to build large Zappa applications by combining reusable, smaller, domain-specific applications. These might turn into reusable components that could be shared and combined into new projects.

More importantly for our goal here, `@include` can be used to split the code that starts the application (the web server) and the application logic itself, as follows.

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

    # test.coffee for mocha
    server = require('zappajs').app ->
      @include './app.coffee'
    express = server.app

    supertest = require 'supertest'

    describe 'GET /health', ->

      it 'returns a 200 OK', (done) ->
        supertest(express)
        .get '/health'
        .expect 'Content-Type', /json/
        .expect 200, done

Note how the application is created using `zappajs.app`, which creates a Node.js server but does not bind it to a specific port.

Run `mocha --compilers coffee:coffee-script/register test.coffee` to confirm the application works as expected.

If you need to make sure the test uses a brand new server each time, move the server creation code inside the tests:

    # test.coffee for mocha
    supertest = require 'supertest'

    new_app = ->
      server = require('zappajs').app ->
        @include './app.coffee'
      server.app

    describe 'GET /health', ->

      express = new_app()

      it 'returns a 200 OK', (done) ->
        supertest(express)
        .get '/health'
        .expect 'Content-Type', /json/
        .expect 200, done

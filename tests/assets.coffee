zappa = require '../src/zappa'
port = 15200
vm = require 'vm'

JS_TYPE = 'application/javascript; charset=utf-8'
CSS_TYPE = 'text/css; charset=utf-8'

@tests =
  client: (t) ->
    t.expect 1, 2, 3
    t.wait 11000

    zapp = zappa port++, ->
      @with 'client'
      @client '/index.js': ->
        @get '#/': -> alert 'hi'

    c = t.client(zapp.server)
    setTimeout ->
      c.get '/index.js', (err, res) ->
        t.equal 1, 3014, res.body.indexOf '''
          require('zappajs-plugin-client').client( function(){
        '''
        t.equal 2, res.headers['content-type'], JS_TYPE
        t.equal 3, 1285190, res.body.length
    , 10000

  browserify: (t) ->
    t.expect 1, 2
    t.wait 11000

    zapp = zappa port++, ->
      @with 'client'
      @browserify '/index.js': ->
        @get '#/': -> alert 'hi'

    c = t.client(zapp.server)
    setTimeout ->
      c.get '/index.js', (err, res) ->
        t.equal 1, res.body, '''
          (function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
          (function (){ var slice = [].slice;var hasProp = {}.hasOwnProperty;var bind = function(fn, me){return function(){ return fn.apply(me, arguments); };};var extend = function(child, parent) {for (var key in parent) {if (hasProp.call(parent, key)) child[key] = parent[key];}function ctor() { this.constructor = child; }ctor.prototype = parent.prototype;child.prototype = new ctor();child.__super__ = parent.prototype;return child;};var indexOf = [].indexOf || function(item) {for (var i = 0, l = this.length; i < l; i++) {if (i in this && this[i] === item) return i;} return -1; };var modulo = function(a, b) { return (+a % (b = +b) + b) % b; }; return (function () {
                      return this.get({
                        '#/': function() {
                          return alert('hi');
                        }
                      });
                    })();})();
          },{}]},{},[1]);

          '''
        t.equal 2, res.headers['content-type'], JS_TYPE
    , 10000

  coffee: (t) ->
    t.expect 1, 2, 3, 4, 5, 6
    t.wait 10000

    zapp = zappa port++, ->
      @coffee '/coffee.js': ->
        alert 'hi'
      @coffee '/slice.js': ->
        [a,b,c...] = 'zappa,hi,zappa,here'.split ','
        alert b
      @coffee '/hasProp.js': ->
        for own k,v of a:1,b:'hi',c:3 when k is 'b'
          alert v
      @coffee '/modulo.js': ->
        a = 8 %% 5
        alert a

    c = t.client(zapp.server)
    c.get '/coffee.js', (err, res) ->
      sandbox =
        alert: (text) ->
          t.equal 1, text, 'hi'
      vm.runInNewContext res.body, sandbox
      t.equal 2, res.headers['content-type'], JS_TYPE

    c.get '/slice.js', (err,res) ->
      sandbox =
        alert: (text) ->
          t.equal 3, text, 'hi'
      vm.runInNewContext res.body, sandbox
      t.equal 4, res.headers['content-type'], JS_TYPE

    c.get '/hasProp.js', (err,res) ->
      sandbox =
        alert: (text) ->
          t.equal 5, text, 'hi'
      vm.runInNewContext res.body, sandbox

    c.get '/modulo.js', (err,res) ->
      sandbox =
        alert: (text) ->
          t.equal 6, text, 3
      vm.runInNewContext res.body, sandbox

  js: (t) ->
    t.expect 1, 2
    t.wait 3000

    zapp = zappa port++, ->
      @js '/js.js': '''
        alert('hi');
      '''

    c = t.client(zapp.server)
    c.get '/js.js', (err, res) ->
      t.equal 1, res.body, "alert('hi');"
      t.equal 2, res.headers['content-type'], JS_TYPE

  css: (t) ->
    t.expect 1, 2
    t.wait 3000

    zapp = zappa port++, ->
      @css '/index.css': '''
        body { font-family: sans-serif; }
      '''

    c = t.client(zapp.server)
    c.get '/index.css', (err, res) ->
      t.equal 1, res.body, 'body { font-family: sans-serif; }'
      t.equal 2, res.headers['content-type'], CSS_TYPE

  coffee_css: (t) ->
    t.expect 1, 2
    t.wait 3000

    zapp = zappa port++, ->
      border_radius = (radius)->
        WebkitBorderRadius: radius
        MozBorderRadius: radius
        borderRadius: radius

      @css '/index.css':
        body:
          font: '12px Helvetica, Arial, sans-serif'

        'a.button':
          border_radius '5px'

    c = t.client(zapp.server)
    c.get '/index.css', (err, res) ->
      t.equal 1, res.body, '''
        body {
            font: 12px Helvetica, Arial, sans-serif;
        }
        a.button {
            -webkit-border-radius: 5px;
            -moz-border-radius: 5px;
            border-radius: 5px;
        }
      '''
      t.equal 2, res.headers['content-type'], CSS_TYPE

  stylus: (t) ->
    t.expect 'header', 'body'
    t.wait 3000

    zapp = zappa port++, ->
      @with css:'stylus'
      @stylus '/index.css': '''
        border-radius()
          -webkit-border-radius arguments
          -moz-border-radius arguments
          border-radius arguments

        body
          font 12px Helvetica, Arial, sans-serif

        a.button
          border-radius 5px
      '''

    c = t.client(zapp.server)
    c.get '/index.css', (err, res) ->
      t.equal 'header', res.headers['content-type'], CSS_TYPE
      t.equal 'body', res.body, '''
        body {
          font: 12px Helvetica, Arial, sans-serif;
        }
        a.button {
          -webkit-border-radius: 5px;
          -moz-border-radius: 5px;
          border-radius: 5px;
        }

      '''

  less: (t) ->
    t.expect 'header', 'body'
    t.wait 3000

    zapp = zappa port++, ->
      @with css:'less'
      @less '/index.css': '''
        .border-radius(@radius) {
          -webkit-border-radius: @radius;
          -moz-border-radius: @radius;
          border-radius: @radius;
        }

        body {
          font: 12px Helvetica, Arial, sans-serif;
        }

        a.button {
          .border-radius(5px);
        }
      '''

    c = t.client(zapp.server)
    c.get '/index.css', (err, res) ->
      t.equal 'header', res.headers['content-type'], CSS_TYPE
      t.equal 'body', res.body, '''
        body {
          font: 12px Helvetica, Arial, sans-serif;
        }
        a.button {
          -webkit-border-radius: 5px;
          -moz-border-radius: 5px;
          border-radius: 5px;
        }

      '''

  'socket.io': (t) ->
    t.expect 'content-type', 'body-length'
    t.wait 3000

    zapp = zappa port++, ->

    c = t.client(zapp.server)
    c.get '/socket.io/socket.io.js', (err, res) ->
      t.equal 'content-type', res.headers['content-type'], 'application/javascript'
      t.equal 'body-length', res.body.length, 184654

 zappa_prefix: (t) ->
    t.expect 1, 2, 3
    t.wait 3000

    zapp = zappa port++, ->
      @set zappa_prefix: '/myapp/zappa'

  'socket.io_path': (t) ->
    t.expect 'content-type', 'body-length'
    t.wait 3000

    zapp = zappa port++, io:{path:'/myapp/socket.io'}, ->

    c = t.client(zapp.server)
    c.get '/myapp/socket.io/socket.io.js', (err, res) ->
      t.equal 'content-type', res.headers['content-type'], 'application/javascript'
      t.equal 'body-length', res.body.length, 174046

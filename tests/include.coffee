zappa = require '../src/zappa'
port = 15400

JS_TYPE = 'application/javascript; charset=utf-8'

@tests =
  client: (t) ->
    t.expect 1, 2
    t.wait 11000

    zapp = zappa port++, ->
      @include './included.coffee'

    c = t.client(zapp.server)
    setTimeout ->
      c.get '/index.js', (err, res) ->
        t.equal 1, res.body, '''
          (function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
          (function (){ var slice = [].slice;var hasProp = {}.hasOwnProperty;var bind = function(fn, me){return function(){ return fn.apply(me, arguments); };};var extend = function(child, parent) {for (var key in parent) {if (hasProp.call(parent, key)) child[key] = parent[key];}function ctor() { this.constructor = child; }ctor.prototype = parent.prototype;child.prototype = new ctor();child.__super__ = parent.prototype;return child;};var indexOf = [].indexOf || function(item) {for (var i = 0, l = this.length; i < l; i++) {if (i in this && this[i] === item) return i;} return -1; };var modulo = function(a, b) { return (+a % (b = +b) + b) % b; }; return (function () {
                  return alert('hi');
                })();})();
          },{}]},{},[1]);

        '''
        t.equal 2, res.headers['content-type'], JS_TYPE
    , 10000

  arguments: (t) ->
    t.expect 1
    t.wait 11000

    zapp = zappa port++, ->
      @include './included.coffee', a:4

    c = t.client(zapp.server)
    setTimeout ->
      c.get '/foo', (err, res) ->
        t.equal 1, res.body, '{"a":4}'
        t.equal 2, res.headers['content-type'], 'application/json; charset=utf-8'
    , 10000

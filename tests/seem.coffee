zappa = require '../src/zappa'
port = 17300
Promise = require 'bluebird'
fs = Promise.promisifyAll require 'fs'
seem = require 'seem'

@tests =
  'seem': (t) ->
    t.expect 1, 2, 3, 4, 5, 6, 7
    t.wait 3000

    zapp = zappa port++, ->
      @get '/package.json', seem ->
        @json JSON.parse yield fs.readFileAsync 'package.json', 'utf-8'

      user_db =
        get: (name) ->
          Promise
          .delay 300
          .then ->
            if name is 'bob'
              {name,age:31,group:'admin'}
            else
              Promise.reject new Error "No such user #{name}"

      group_db =
        get: (name) ->
          Promise
          .delay 340
          .then ->
            switch name
              when 'admin'
                {name,roles:['_admin']}
              when 'user'
                {name,roles:[]}
              else
                Promise.reject new Error "No such group #{name}"

      @get '/user/:name', seem ->
        user = yield user_db.get @params.name
        group = yield group_db.get user.group
        @json {user,group}

    c = t.client(zapp.server)

    c.get '/package.json', headers:{Accept:'application/json'}, (err, res) ->
      body = JSON.parse res.body
      t.equal 1, body.name, 'zappajs'

    c.get '/user/bob', (err,res) ->
      body = JSON.parse res.body
      t.equal 2, body.user.name, 'bob'
      t.equal 3, body.user.age, 31
      t.equal 4, body.group.name, 'admin'
      t.equal 5, body.group.roles[0], '_admin'

    c.get '/user/nathan', (err,res) ->
      t.equal 6, res.statusCode, 500
      t.ok 7, res.body.match /^Error: No such user nathan/

io = require 'socket.io'
snakeController = require './snake/main'
socketioJwt = require 'socketio-jwt'
Player = require './snake/player'
User = require('./snake/models').user

sockets = null

exports = module.exports =
  sockets: ->
    sockets

  init: (server) ->
    # Socket join flow
    io = io.listen server
    io.set 'log level', 1

    sockets = io.sockets

    io.set 'authorization', socketioJwt.authorize 
      secret: config.JWT_Token,
      handshake: true

    io.sockets.on 'connection', (socket) ->
      address = socket.handshake.address
      client_ip = address.address

      # New player joining
      socket.on 'ready', (data) ->
        id = socket.handshake.decoded_token.id
      
        User.findOne { _id: id }, (err, meta) =>
          player = 
            meta: meta
            id: id

          # emit joined
          socket.emit 'attach-client', player

          # join game
          player.socket = socket
          snakeController.joinGame player
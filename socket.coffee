io = require 'socket.io'
snakeController = require './snake/main'
Player = require './snake/player'
store = require './store'

module.exports = 
  init: (server) ->
    # Socket join flow
    io = io.listen server
    io.set 'log level', 1
    io.sockets.on 'connection', (socket) ->
      address = socket.handshake.address
      client_ip = address.address

      # New player joining
      socket.on 'ready', ->
        id = client_ip
      
        store.findOrCreate id, (err, meta) =>
          player = 
            meta: meta
            id: id

          # emit joined
          socket.emit 'attach-client', player

          # join game
          player.socket = socket
          snakeController.joinGame player
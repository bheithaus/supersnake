utils = require('lodash')
Game = require('./game')

includes = (bodyPieces, head) ->
  utils(bodyPieces).any((piece)-> piece[0] == head[0] && piece[1] == head[1]) 



module.exports = class Controller
  constructor: (player) ->
    @game = new Game 50, player
    @bindEvents player
    @runLoop()
    
  join: (player) =>
    @game.addPlayer player
    @bindEvents player

  keyPress: (keyCode, id) =>
    if 36 < keyCode < 41
      @turn keyCode, id
    else if keyCode is 80
      @pause id

  turn: (keyCode, id) =>    
    @game.players[id].snake.turn keyCode

  pause: (id) =>
    @paused = if @paused is id then null else if not @paused then id else @paused
    @runStep() if not @paused

  updateClients: (state) ->
    utils(@game.players).each (player, id) ->
      player.socket.emit 'update-client', state

  bindEvents: (player) =>
    player.socket.on 'keypress', @keyPress

  runStep: =>
    @game.step()
    over = @game.lose()
    state = @game.zip(@paused)

    if over
      state.endGame = 
        code: over

    @updateClients state
    @runLoop() if not @paused and not over

  reset: ->
    # @game = new Game(50)

  runLoop: ->
    setTimeout @runStep, @stepTime()

  stepTime: ->
    100

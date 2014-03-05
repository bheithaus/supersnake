utils = require 'lodash'
Game = require './game'
Player = require './player'
User = require('./models').user

includes = (bodyPieces, head) ->
  utils(bodyPieces).any((piece) -> piece[0] == head[0] && piece[1] == head[1])

module.exports = class Controller
  constructor: (player) ->
    @id = utils.uniqueId() 

    # create a one player game with AI
    @newPracticeGame player
  
  newPracticeGame: (player) ->
    @game = new Game @, 50, player
    @bindEvents player
    @updateClients null, true, true
    @runStep()

  # human has arrived, so create a new game with two players
  join: (human) =>
    clearTimeout @timeout

    other = player for id, player of @game.players when id isnt 'AI'
    @game = new Game @, 50, other, human
    @bindEvents human
    @updateClients human.id, true

    setTimeout (() => @runStep true), 2000

  # turn as in, turn the snake a certain direction
  turn: (code, id) =>
    # console.log code, id
    @game.players[id].snake.turn code

  pause: (id) =>
    paused = @game.paused
    @game.paused = if paused is id then null else if not paused then id else paused
    
    @runStep() if not @game.paused

  updateClients: (incoming, newGame, open) ->
    state = @game.zip incoming, newGame, open
 
    for id, player of @game.players
      # console.log 'update!', @game.players
      player.socket.emit 'update-client', state

  updateTotalGames: (count) ->
    for id, player of @game.players
      player.socket.emit 'update-total-games', count

  scoreClient: (player, inc) ->
    update =
      gameCount: player.meta.gameCount + (inc.gameCount || 0)
      winCount: player.meta.winCount + (inc.winCount || 0)
      growth: player.meta.growth + (inc.growth || 0)
      
    player.socket.emit 'score-client', update

  tearDownStartAnew: (id) ->
    player = @game.players[id]
    if player
      @unbindEvents player

    delete @game.players[id]

    if not (Object.keys @game.players)[0]?length
      Controller.remove @id

    Controller.joinGame player

  # Some special treatment going on to namespace
  # and bind these to @
  _socketEvents:
    disconnect: (caller) ->
      () ->
        (() ->
          clearTimeout @timeout
          @game.end true
          @updateClients())

        .apply(caller, arguments)

    keypress:  (caller) ->
      () ->
        ((code, id) ->
          if @game.endGame
            return @tearDownStartAnew(id) if code is 13
            return 

          if 36 < code < 41
            @turn code, id

          else if code is 80
            @pause id)
        .apply(caller, arguments)

  bindEvents: (player) =>
    for key, handler of @_socketEvents
      player.socket.on key, handler(@)
  
  unbindEvents: (player) =>
    for key, handler of @_socketEvents
      player.socket.removeAllListeners key

  runStep: () =>
    @game.step()
    @close() if @game.endGame
    @updateClients()
    @runLoop() if not @game.paused and not @game.endGame

  runLoop: ->
    @timeout = setTimeout @runStep, @game.stepTime()

  close: ->
    for id, player of @game.players
      return if id is 'AI'
      
      inc =
        $inc: 
          gameCount: 1
          growth: player.snake.body.length - 15

      if typeof @game.endGame is 'string'
        inc.$inc.winCount = 1 if id isnt @game.endGame

      @scoreClient player, inc.$inc
      ## update client score here

      User.findOneAndUpdate { _id: id }, inc, (err) =>
        return console.error err if err

# all current games
controllers = {}

# Class Methods
Controller.availableGames = ->
  (controller for id, controller of controllers when controller.game.open and not controller.game.endGame and not controller.game.paused)

Controller.remove = (id) ->
  delete controllers[id]


Controller.updateGameCount = ->
  # could have big problems here at scale.. over triggering this event
  count = Object.keys(controllers).length
  for id, controller of controllers
    controller.updateTotalGames count


# Handles Placing players into two player games
Controller.joinGame = (player) ->
  available = Controller.availableGames()

  if available.length
    # console.log 'here '
    # join game with waiting player
    available[0].join player
  else
    # create new single player game
    controller = new Controller player
    controllers[controller.id] = controller

    Controller.updateGameCount()
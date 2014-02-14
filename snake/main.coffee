utils = require('lodash')
Game = require('./game')

includes = (bodyPieces, head) ->
  utils(bodyPieces).any((piece) -> piece[0] == head[0] && piece[1] == head[1])

module.exports = class Controller
  constructor: (player) ->
    console.log 'controller!', player
    # create a one player game, with AI
    @game = new Game @, 50, player
    @bindEvents player
    @runStep true
    @id = utils.uniqueId()
  
  # human has arrived, so create a new game with two players
  join: (human) =>
    clearTimeout @timeout

    other = player for id, player of @game.players when id isnt 'AI'
    @game = new Game @, 50, other, human
    @bindEvents human

    console.log 'join new client, settime'
    @updateClients human.id

    setTimeout (() => @runStep true), 1000

  turn: (code, id) =>
    # console.log code, id
    @game.players[id].snake.turn code
    @updateRequired = true

  pause: (id) =>
    paused = @game.paused
    @game.paused = if paused is id then null else if not paused then id else paused
    @updateRequired = true
    
    @runStep() if not @game.paused

  updateClients: (incoming, newGame) ->
    @updateRequired = false
    state = @game.zip(incoming, newGame)

    for id, player of @game.players
      console.log 'update!', @game.players
      player.socket.emit 'update-client', state

  tearDownStartAnew: (id) ->
    player = @game.players[id]
    if player
      console.log player
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

  runStep: (newGame) =>
    @game.step()
    @updateClients(null, newGame) if newGame or @game.endGame or @updateRequired
    @runLoop() if not @game.paused and not @game.endGame

  runLoop: ->
    @timeout = setTimeout @runStep, @game.stepTime()

# all current games
controllers = {}

# Class Methods
Controller.availableGames = () ->
  (controller for id, controller of controllers when controller.game.open and not controller.game.endGame and not controller.game.paused)

Controller.remove = (id) ->
  delete controllers[id]

# Handles Placing players into two player games
Controller.joinGame = (player) ->
  console.log 'join game', player
  available = Controller.availableGames()

  console.log 'available', available
  if available.length
    # console.log 'here '
    # join game with waiting player
    available[0].join player
  else
    # create new single player game
    controller = new Controller(player)
    controllers[controller.id] = controller
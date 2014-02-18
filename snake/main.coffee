utils = require('lodash')
Game = require('./game')
store = require '../store'

includes = (bodyPieces, head) ->
  utils(bodyPieces).any((piece) -> piece[0] == head[0] && piece[1] == head[1])

module.exports = class Controller
  constructor: (player) ->
    @id = utils.uniqueId()
    # create a one player game, with AI
    @newPracticeGame player
  
  newPracticeGame: (player) ->
    @cyclesSinceUpdate = 0
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
    @cyclesSinceUpdate = 0
    @updateRequired = false
    state = @game.zip incoming, newGame, open

    # console.log 'newGame? ', newGame, state

    for id, player of @game.players
      # console.log 'update!', @game.players
      player.socket.emit 'update-client', state

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

  updateCounter: () ->
    @cyclesSinceUpdate++
    if @cyclesSinceUpdate > 4
      @updateRequired = true

  runStep: () =>
    @game.step()
    @close() if @game.endGame
    @updateClients()
    @runLoop() if not @game.paused and not @game.endGame

  runLoop: ->
    @timeout = setTimeout @runStep, @game.stepTime()

  close: ->
    for id, player of @game.players
      console.log player.snake.body.length
      
      inc = 
        $inc: 
          gameCount: 1
          growth: player.snake.body.length - 15

      if typeof @game.endGame is 'string'
        inc.$inc.winCount = 1 if id isnt @game.endGame

      store.Player.findOneAndUpdate { pid: id }, inc, (err, player) =>
        return console.error err if err
        console.log player

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
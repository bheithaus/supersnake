utils = require('lodash')
Snake = require('./snake')
AIPlayer = require('./ai')

includes = (bodyPieces, head) ->
  utils(bodyPieces).any((piece)-> piece[0] == head[0] && piece[1] == head[1]) 

module.exports = class Game
  constructor: (@controller, boardSize, player, second) ->
    @boardSize = boardSize
    @food = [@randomCoord()]
    @players = {}
    @addPlayer player

    # two human players
    return @addPlayer second if second

    # one human vs. AI
    @addPlayer new AIPlayer(@)
    @open = true

  stepTime: () ->
    100

  addPlayer: (player) =>
    # give them a snake
    player.snake = new Snake @randomCoord()
    # add to list
    @players[player.id] = player
    @open = false
    @

  zip: (incoming, newGame) ->
    snakes: utils(@players).map((player, key) ->
      player.snake
    ).value()
    food: @food
    size: @boardSize
    paused: @paused
    open: @open
    stepTime: @stepTime()
    endGame: @endGame
    incoming: incoming
    newGame: newGame

  collision: ->
    bodies = []
    losers = []
    bodies = bodies.concat( player.snake.body[1..] ) for id, player of @players

    # got your head in the pile? then, ya lose!
    losers.push id for id, player of @players when includes bodies, player.snake.body[0]

    losers

  step: ->
    for id, player of @players
      snake = player.snake
      # console.log id, new Date().getTime()
      player.choose() if id is 'AI'

      snake.move()
      @hitEdge snake

      @feast snake  if @hitFood snake

    # Test for endGame
    @end()

  feast: (snake) ->
    snake.eat()
    @food.pop()
    @generateFood(1)
    @controller.updateClients()

  randomCoord: ->
    Math.floor(Math.random() * @boardSize) for times in [1,1]

  generateFood: (amount) ->
    utils(amount).times =>
      newFood = @randomCoord()
      newFood = @randomCoord() until not @snakesTouching newFood
      @food.push newFood

  snakesTouching: (newFood) ->
    utils(@players).any (player) ->
      includes player.snake.body, newFood

  hitFood: (snake) ->
    includes @food, snake.body[0]

  end: (quit) ->
    collision = @collision()

    @endGame = if quit then -2 else switch collision.length
      when 0 then null
      when 1 then collision[0]
      when 2 then -1

  hitEdge: (snake) =>
    snake.body[0][0] += @boundsOneWay(snake.body[0][0]) * @boardSize
    snake.body[0][1] += @boundsOneWay(snake.body[0][1]) * @boardSize

  boundsOneWay: (position) ->
    return 1 if position < 0
    return -1 if position >= @boardSize

    0
    
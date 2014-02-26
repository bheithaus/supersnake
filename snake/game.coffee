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

    # two human players case
    return @addPlayer second if second

    # one human vs. AI
    @addPlayer new AIPlayer(@)
    @open = true

  stepTime: () ->
    lengths = 0
    for id, player of @players
      lengths += player.snake.length
    
    130 - lengths

  addPlayer: (player) =>
    # give them a snake
    player.snake = new Snake @randomCoord()
    # add to list
    @players[player.id] = player
    @

  zip: (incoming, newGame, open) ->
    zipped = 
      s: utils(@players).mapValues((player, key) ->
        player.snake.zip()
      ).value()
      f: @food

    zipped.o = true if open
    zipped.i = true if incoming
    zipped.n = true if newGame
    zipped.p = @paused if @paused
    zipped.e = @endGame if @endGame
    zipped.ate = @ate if @ate

    @ate = null
    zipped

  collision: ->
    bodies = []
    losers = []
    bodies = bodies.concat player.snake.body[1..]  for id, player of @players

    # got your head in the pile? --> ya lose!
    losers.push id for id, player of @players when includes bodies, player.snake.body[0]
    
    losers

  step: ->
    for id, player of @players
      player.choose() if id is 'AI'
      
      snake = player.snake
      snake.move()
      @hitEdge snake
      @feast snake, id if @hitFood snake

    # Test for endGame
    @end()

  feast: (snake, id) ->
    @ate = id
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
    
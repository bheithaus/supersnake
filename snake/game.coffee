utils = require('lodash')
Snake = require('./snake')
includes = (bodyPieces, head) ->
  utils(bodyPieces).any((piece)-> piece[0] == head[0] && piece[1] == head[1]) 



EventEmitter = require('events').EventEmitter
class EE extends EventEmitter

class AIPlayer
  constructor: (@game) ->
    @id = 'AI-One'
    @snake = new Snake @game.randomCoord()
    @socket = new EE()


  brain: ->
    console.log 'food', @game.food
    console.log 'head', @snake.body[0]




module.exports = class Game
  constructor: (boardSize, player) ->
    @boardSize = boardSize
    @food = [@randomCoord()]
    @players = {}
    @addPlayer player
    @addPlayer new AIPlayer(@)

  addPlayer: (player) =>
    # give them a snake
    player.snake = new Snake @randomCoord()
    # add to list
    @players[player.id] = player

  zip: (paused) ->
    snakes: utils(@players).map((player, key) ->
      player.snake
    ).value()
    food: @food
    size: @boardSize
    paused: paused

  collision: ->
    bodies = []
    losers = []
    bodies = bodies.concat( player.snake.body[1..] ) for id, player of @players

    losers.push id for id, player of @players when includes bodies, player.snake.body[0]

    losers

  step: ->
    for id, player of @players
      if id is 'AI-One'
        player.brain()

      snake = player.snake
      snake.move()
      @hitEdge snake

      if @hitFood snake
        snake.eat()
        @food.pop()
        @generateFood(1)
      
    
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

  lose: () ->
    collision = @collision()
    # if collision.length
    # console.log collision

    switch collision.length
      when 0 then false
      when 1 then collision[0]
      when 2 then -1;

  hitEdge: (snake) =>
    snake.body[0][0] += @boundsOneWay(snake.body[0][0]) * @boardSize;
    snake.body[0][1] += @boundsOneWay(snake.body[0][1]) * @boardSize;

  boundsOneWay: (position) ->
    return 1 if position < 0
    return -1 if position >= @boardSize

    0
    
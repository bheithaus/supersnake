utils = require('lodash')

includes = (bodyPieces, head) ->
    utils(bodyPieces).any((piece)-> piece[0] == head[0] && piece[1] == head[1]) 

module.exports = class Snake
  constructor: (@body...) ->
    @length = 15
    @oldDirection = [1,0]
    @direction = [1,0]

  move: ->
    @oldDirection = @direction
    @body.unshift @addVector(@body[0], @direction)

    # console.log(@body)
    @body.pop() if @body.length > @length

  zip: ->
    l: @length
    d: @direction
    h: @body[0]

  eat: ->
    @length += 1

  inform: (grid) =>
    @grid = grid

  directions:
    37: [-1, 0]
    38: [0, -1]
    39: [1, 0]
    40: [0, 1]

  canTurn: (keyCode) ->
    newDirection = @directions[keyCode]
    return if not newDirection
    return if @sameCoords [0,0], @addVector(newDirection, @oldDirection)
    return if @sameCoords newDirection, @oldDirection
    
    true

  turn: (keyCode) ->
    return if not @canTurn keyCode

    @direction = @directions[keyCode]
    
#helpers
  addVector: (position, vector) ->
    [position[0] + vector[0], position[1] + vector[1]]

  sameCoords: (c1, c2) ->
    c1[0] == c2[0] && c1[1] == c2[1]


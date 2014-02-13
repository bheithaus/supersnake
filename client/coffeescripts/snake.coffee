includes = (bodyPieces, head) ->
    _(bodyPieces).any((piece)-> piece[0] == head[0] && piece[1] == head[1]) 

class Game
  constructor: (boardSize) ->
    @boardSize = boardSize

  set: (state) ->
    @snakes = state.snakes
    @food = state.food

    if state.endGame
      @over = state.endGame

  makeSnakes: (number) ->
    new Snake (@randomCoord()) for i in [1,1]

  collision: ->
    bodies = []
    losers = []
    bodies = bodies.concat snake.body[1..] for snake, i in @snakes

    losers.push i + 1 for snake, i in @snakes when includes bodies, snake.body[0]

    losers

  step: ->
    for snake in @snakes
      snake.move()
      @hitEdge snake
    
  randomCoord: ->
    Math.floor(Math.random() * @boardSize) for times in [1,1]

  hitEdge: (snake) ->
    snake.body[0][0] += @boundsOneWay(snake.body[0][0]) * @boardSize;
    snake.body[0][1] += @boundsOneWay(snake.body[0][1]) * @boardSize;

  boundsOneWay: (position) ->
    return 1 if position < 0
    return -1 if position >= @boardSize

    0

class Snake
  constructor: (@body...) ->
    @length = 15
    @oldDirection = [1,0]
    @direction = [1,0]

  oroborus: ->
    _(@body.slice 1).contains(@body[0])

  move: ->
    @oldDirection = @direction
    newPosition = @addVector(@body[0], @direction)
    @body.unshift(@addVector(@body[0], @direction))
    @body.pop() if @body.length > @length

  eat: ->
    @length += 1

  directions:
    37: [-1, 0]
    38: [0, -1]
    39: [1, 0]
    40: [0, 1]

  turn: (keyCode) ->
    newDirection = @directions[keyCode]

    console.log 'newDirection', newDirection

    return if not newDirection
    return if @sameCoords [0,0], @addVector(newDirection, @oldDirection)
    return if @sameCoords newDirection, @oldDirection
    
    @direction = newDirection
    true


#helpers
  addVector: (position, vector) ->
    [position[0] + vector[0], position[1] + vector[1]]

  sameCoords: (c1, c2) ->
    c1[0] == c2[0] && c1[1] == c2[1]

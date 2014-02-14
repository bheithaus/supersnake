includes = (bodyPieces, head) ->
    _(bodyPieces).any((piece)-> piece[0] == head[0] && piece[1] == head[1]) 

class Game
  constructor: (@boardSize, @id) ->
    @snakes = @makeSnakes 2

  update: (state) ->
    @food = state.food
    @updateSnakes(state.snakes)
    @open = state.open
    @stepTime = state.stepTime
    @paused = state.paused

    if state.endGame
      @endGame = state.endGame

  updateSnakes: (updates) ->
    for snake, i in @snakes
      snake.update updates[i].body, updates[i].oldDirection, updates[i].direction

  makeSnakes: (number) ->
    new Snake (@randomCoord()) for i in [1,1]

  step: ->
    for snake in @snakes
      snake.move()
      @hitEdge snake
    
  randomCoord: ->
    Math.floor(Math.random() * @boardSize) for times in [1,1]

  hitEdge: (snake) ->
    snake.body[0][0] += @boundsOneWay(snake.body[0][0]) * @boardSize
    snake.body[0][1] += @boundsOneWay(snake.body[0][1]) * @boardSize

  boundsOneWay: (position) ->
    return 1 if position < 0
    return -1 if position >= @boardSize

    0

class Snake
  constructor: (@body...) ->
    @length = 15
    @oldDirection = [1,0]
    @direction = [1,0]

  # oroborus: ->
  #   _(@body.slice 1).contains(@body[0])

  update: (@body, @oldDirection, @direction) ->

  move: ->
    @oldDirection = @direction
    @body.unshift(@addVector(@body[0], @direction))
    @body.pop() if @body.length > @length

  eat: ->
    @length += 1

#helpers
  addVector: (position, vector) ->
    [position[0] + vector[0], position[1] + vector[1]]

  sameCoords: (c1, c2) ->
    c1[0] == c2[0] && c1[1] == c2[1]

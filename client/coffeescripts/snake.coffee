includes = (bodyPieces, head) ->
    _(bodyPieces).any((piece)-> piece[0] == head[0] && piece[1] == head[1]) 

class Game
  constructor: (@boardSize, @id, snakes, @open) ->
    @snakes = @makeSnakes snakes

  update: (state) ->
    @updateSnakes state.s
    @food = state.f
    @paused = state.p

    if state.e
      @endGame = state.e

  updateSnakes: (updates) ->
    for id, snake of updates
      @snakes[id].update snake.h , snake.d, snake.l

  makeSnakes: (snakes) ->
    _(snakes).mapValues((snake, id) => 
      new Snake snake
    ).value()

  step: ->
    for id, snake of @snakes
      snake.move()
      @hitEdge snake
    
  randomCoord: ->
    Math.floor(Math.random() * @boardSize) for times in [1,1]

  hitEdge: (snake) ->
    snake.body[0][0] += @boundsOneWay(snake.body[0][0]) * @boardSize
    snake.body[0][1] += @boundsOneWay(snake.body[0][1]) * @boardSize

  boundsOneWay: (position) ->
    if position < 0
      1
    else if position >= @boardSize
      -1
    else
      0

class Snake
  constructor: (@body...) ->
    @length = 15
    @oldDirection = [1,0]
    @direction = [1,0]

  update: (head, @direction, @length) ->
    @body.unshift(head)
    @body.pop() if @body.length > @length

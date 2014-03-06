CIRCLE = Math.PI * 2

$document = $(document)

FONTS = 
  score: "bold 12px sans-serif"
  prompt: "bold 20px zapfino"

PAUSE_PROMPTS =
  self: 'You paused the game'
  other: 'The other player paused the game'

COLORS =
  background: '#E6E6C3'
  players: [
    'black'
    'blue'
  ]

# /* Controllers */
angular.module 'supersnake.controllers'

.controller 'GameCtrl', ($scope, $http, $location, LoginModal, User, socket) ->
  socket.emit 'ready'

  # choose a new AI algorithm
  $scope.chooseAlgorithm = (selected) ->
    $scope.algorithm = selected
    socket.emit 'chooseAlgorithm', window.client.player.id, selected

  # On joining
  socket.on 'attach-client', (player) =>
    # console.log 'attach player', player
    # Instantiate Client
    client = window.client = new clientController socket, player
    $document.trigger 'score-client'
    
    socket.on 'update-client', client.state

    socket.on 'ai-algorithms', (algorithms) ->
      $scope.$apply ->
        $scope.algorithm = algorithms.current
        $scope.algorithms = algorithms.options

    socket.on 'score-client', (meta) ->
      window.client.player.meta = meta
      $document.trigger 'score-client'

    socket.on 'update-total-games', (count) ->
      window.client.concurrentGames = count
      $document.trigger 'update-total-games'


# Client Controller Class
class clientController
  constructor: (@socket, @player) ->
    @canvas = $ 'canvas'
    @context = @canvas[0].getContext '2d'

  newGame: (state, incoming) ->
    @game = new Game 50, @player.id, state.s, state.o
    @bindKeyDown()

  namespace: '.snake'

  render: =>
    @clear()
    @drawSnakes()
    @drawScore()
    @drawFood()

    if @game.open
      @drawPractice()

  translate: (pos) ->
    10 * pos + 5

  drawCircle: (pos, color, head) ->
    radius = if head then 6 else 5
    @context.beginPath()
    @context.arc @translate(pos[0]), @translate(pos[1]), radius, 0, CIRCLE, false
    @context.fillStyle = color
    @context.fill()

  clear: ->
    @context.clearRect 0, 0, 500, 500

  drawPractice: ->
    @context.font = FONTS.score
    @context.textAlign = "left"
    @context.fillStyle = 'orange'
    @context.fillText 'Awaiting player - in Practice Mode', 10, 10  

  drawSnakes: ->
    iterator = 0
    for id, snake of @game.snakes
      # draw body
      for piece in snake.body[1..]
        @drawCircle piece, '#435E3B'

      # draw head
      @drawCircle snake.body[0], COLORS.players[iterator], true
      iterator++


  drawFood: ->
    for food in @game.food
      @drawCircle food, 'red'

  drawScore: ->
    @context.font = FONTS.score
    @context.textAlign = "left"

    iterator = 0
    for id, snake of @game.snakes
      @context.fillStyle = COLORS.players[iterator]
      @context.fillText "Score: " + snake.body.length, 435, 15 + (15 * iterator)
      iterator++

  drawPause: ->
    @drawPrompt PAUSE_PROMPTS[(if @game.paused == @player.id then 'self' else 'other')], "blue", true
  
  incomingPlayer: (state) ->
    @started = null
    a = 0
    dir = 1
    incoming = () =>
      return console.log 'starting' if @started
      a += dir * 0.05
      dir = if a >= 1 then -1 else if a <= 0 then 1 else dir

      @drawPrompt 'Joining new Human vs. Human game', COLORS.background
      @drawPrompt 'Joining new Human vs. Human game', 'rgba(0, 20, 200, ' + a + ')'
      
      setTimeout incoming, 60
    
    incoming()


  drawPrompt: (text, color, pause) ->
    x = y = @game.boardSize * 10 / 2
    y = 100 if pause

    @context.fillRect 'black', x, y, 800, 200
    @context.font = FONTS.prompt
    @context.textAlign = "center"
    @context.fillStyle = color if color

    @context.fillText text, x, y

  bindKeyDown: =>
    $document.off @namespace

    $document.on 'keydown' + @namespace, (event) =>
      code = event.keyCode

      if 36 < code < 41 or code is 80 or code is 13
        event.preventDefault()
        event.stopPropagation()
        @socket.emit 'keypress', code, @player.id


  runStep: (state) =>
    @game.update state
    @started = true if not @started
    if not @game.endGame
      return @drawPause() if @game.paused
      @render()
    else
      # game over :p
      @render()

      loser = @game.endGame

      prompt = switch loser 
        when -2 then 'Opponent Quit!'
        when -1 then "Tie game"
        when @player.id then "You Lost"
        else "You Won"

      @drawPrompt prompt + "! >--< Press Enter.", "red"
      @game.endGame = null

  # Catch Update
  state: (state) =>
    @newGame state if state.n
    return @incomingPlayer state if state.i

    @runStep state
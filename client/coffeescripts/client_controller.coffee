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

class clientController
  constructor: (@socket, @id) ->
    @game = new Game 50, @id
    @canvas = $ 'canvas'
    @context = @canvas[0].getContext '2d'

  namespace: '.snake'

  render: ->
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
    @context.fillText('Awaiting player - in Practice Mode', 10, 10)    

  drawSnakes: ->
    for snake, i in @game.snakes
      # draw body
      for piece in snake.body[1..]
        @drawCircle piece, '#435E3B'

      # draw head
      @drawCircle snake.body[0], COLORS.players[i], true


  drawFood: ->
    for food in @game.food
      @drawCircle food, 'red'

  drawScore: ->
    @context.font = FONTS.score
    @context.textAlign = "left"

    for snake, i in @game.snakes
      @context.fillStyle = COLORS.players[i]
      @context.fillText "Score: " + snake.body.length, 435, 15 + (15 * i)

  drawPause: ->
    @drawPrompt PAUSE_PROMPTS[(if @game.paused == @id then 'self' else 'other')], "blue", true
  
  incomingPlayer: (incoming) ->
    # console.log 'run incoming, set @started = null'
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
        @socket.emit 'keypress', code, @id


  runStep: =>
    if @newState
      @game.update @newState
      incoming = @newState.incoming
      @newState = null

      return if incoming
    else 
      @game.step()

    if not @game.endGame
      return @drawPause() if @game.paused
      @render()
      @runLoop()      
    else
      @render()

      loser = @game.endGame

      prompt = switch loser 
        when -2 then 'Opponent Quit!'
        when -1 then "Tie game"
        when @id then "You Lost"
        else "You Won"

      @drawPrompt prompt + "! >--< Press Enter.", "red"
      @game.endGame = null

  newGame: () ->
    @bindKeyDown()
    @started = true
    @running = true

    @runStep()

  # Catch Update
  state: (state) =>
    @newState = state
    return @incomingPlayer() if state.incoming

    if state.newGame
      @newGame()
    else if @game.paused
      # game paused, but action required
      @runStep() if state.endGame or not state.paused

  # use Updated state to modify game
  update: =>
    @game.update @newState
    @newState = null

  runLoop: ->
    @timeout = window.setTimeout @runStep, @game.stepTime

$document.ready ->
  client = null
  socket = io.connect window.location.origin

  # Join Game
  socket.emit 'ready'

  # On joining
  socket.on 'attach-client', (id) =>
    # Instantiate Client
    client = window.client = new clientController(socket, id)
    socket.on 'update-client', client.state
    






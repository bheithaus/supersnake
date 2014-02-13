CIRCLE = Math.PI * 2
$document = $(document)

FONTS = 
  score: "bold 12px sans-serif"
  prompt: "bold 20px zapfino"

PAUSE_PROMPTS =
  self: 'You paused the game'
  other: 'The other player paused the game'

class clientController
  constructor: (@socket, @id) ->
    @game = new Game 50
    @canvas = $ 'canvas'
    @context = @canvas[0].getContext '2d'
    @bindKeyDown()

  colors: [
    'black',
    'blue'
  ]

  render: ->
    @clear()
    @drawSnakes()
    @drawScore()
    @drawFood()

  translate: (pos) ->
    10 * pos + 5

  drawCircle: (pos, color) ->
    @context.beginPath()
    @context.arc @translate(pos[0]), @translate(pos[1]), 5, 0, CIRCLE, false
    @context.fillStyle = color
    @context.fill()

  clear: ->
    @context.clearRect(0,0,500,500)

  drawSnakes: ->
    for snake, i in @game.snakes
      # draw head
      @drawCircle snake.body[0], @colors[i]

      # draw body
      for piece in snake.body[1..]
        @drawCircle piece, '#435E3B'

  drawFood: ->
    for food in @game.food
      @drawCircle food, 'red'

  drawScore: ->
    @context.font = FONTS.score
    @context.textAlign = "left"

    for snake, i in @game.snakes
      @context.fillStyle = @colors[i]
      @context.fillText "Score: " + snake.length, 435, 15 + (15 * i)


  drawPrompt: (text, color) ->
    @context.font = FONTS.prompt
    @context.textAlign = "center"
    @context.fillStyle = color
    @context.fillText(text, 250, 250)

  bindKeyDown: =>
    $document.on 'keydown', (event) =>
      if 36 < event.keyCode < 41 or event.keyCode is 80
        @socket.emit 'keypress', event.keyCode, @id

  pause: (state) ->
    @paused = true
    prompt = PAUSE_PROMPTS[(if state.paused == @id then 'self' else 'other')]
    @drawPrompt prompt, "blue"

  runStep: =>
    # @game.step();
    @render()

    if not @game.over
      @runLoop()
    else
      loser = @game.over.code

      prompt = if loser is -1
      then "Tie game"
      else if loser is @id
      then "You Lost"
      else "You Won"

      @drawPrompt prompt + "! >--< Click to Restart.", "red"
      @game.over = null

  update: (state) =>
    @game.set state

    return @pause(state) if state.paused

    # @runStep()

  reset: ->
    # @game = new Game(50)

  runLoop: ->
    window.setTimeout @runStep, @stepTime()

  stepTime: ->
    return 100
    # 125 - @game.snakes[0].length - @game.snakes[1].length

$document.ready ->
  client = null
  socket = io.connect 'http://localhost'
  # controller.addStartHandler();
  # controller.drawPrompt("Start Game", "#818267");

  # Join Game
  socket.emit('ready')

  # On joining
  socket.on 'join-client', (id) =>
    console.log id
    # Instantiate Client
    client = window.client = new clientController(socket, id)
    
    socket.on 'update-client', client.update
    client.runLoop()






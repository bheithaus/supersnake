Snake = require './snake'
EventEmitter = require('events').EventEmitter
class EE extends EventEmitter

PathFinding = require 'pathfinding'

class AIPlayer
  constructor: (@game) ->
    @id = 'AI'
    @snake = new Snake @game.randomCoord()
    opponent = player for id, player of @game.players when id isnt @id
    @other = opponent.snake
    @socket = new EE()

    @algorithm = opponent.meta.opponent_preference

    # bind myself to controller
    @game.controller.bindEvents @

  destroy: =>
    @game.controller.unbindEvents @

  directions:
    '-1': 
      '0': 37
    '0':
      '-1': 38
      '1': 40
    '1': 
      '0': 39 

  choose: =>
    choice = @brain()
    if choice and choice isnt @lastChoice
      @lastChoice = choice
      @socket.emit 'keypress', choice, @id

  lastMove: null

  buildBrain: () ->
    s = @game.boardSize
    grid = new PathFinding.Grid(s, s)

    @algorithm = if AIPlayer.algorithms.indexOf(@algorithm) is -1
    then 'AStarFinder'
    else @algorithm

    finder = new PathFinding[@algorithm]()

    for id, player of @game.players
      for piece, i in player.snake.body
        continue if i is 0 and id is @id
        grid.setWalkableAt piece[0], piece[1], false

    brain =   
      grid: grid
      finder: finder

  brain: ->
    food = @game.food[0]
    head = @snake.body[0]
    brain = @buildBrain()
    path = brain.finder.findPath(head[0], head[1], food[0], food[1], brain.grid);
    next = path[1]
    return if not next

    @directions[next[0] - head[0]][next[1] - head[1]]


AIPlayer.algorithms = [
  'AStarFinder'
  'BreadthFirstFinder'
  'BestFirstFinder'
  'DijkstraFinder'
  'BiAStarFinder'
  'BiBestFirstFinder'
  'BiDijkstraFinder'
  'BiBreadthFirstFinder'
  'JumpPointFinder'
]
    

module.exports = AIPlayer

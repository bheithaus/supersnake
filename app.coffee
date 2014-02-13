express = require 'express'
io = require 'socket.io'
http =  require 'http'
path = require 'path'
snakeController = require './snake/main'
EventEmitter = require('events').EventEmitter
class EE extends EventEmitter
Events = new EE()

paths =
  bower:  express.static path.join(__dirname, '/bower_components')
  public: express.static path.join(__dirname, '/public')


routes = require './routes'
user = require './routes/user'

app = express()

#  all environments
app.set 'port', process.env.PORT || 3000
app.set 'views', path.join(__dirname, '/views')
app.set 'view engine', 'jade'

# static files
app.use paths.bower
app.use paths.public

app.use express.favicon()
app.use express.logger('dev')
app.use express.json()
app.use express.urlencoded()
app.use express.methodOverride()
app.use app.router

# development only
if 'development' == app.get('env')
  app.use express.errorHandler()

app.get '/',      routes.index
app.get '/users', user.list

# setup Servers
server = http.createServer(app)
io = io.listen server
io.set 'log level', 1

# start server
server.listen app.get('port'), () =>
  console.log('Express server listening on port ' + app.get('port'));

generateUUID = (ip)->
  d = new Date().getTime() + ip.replace /\./g, ''

  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace /[xy]/g, (c) ->
    r = (d + Math.random()*16)%16 | 0
    d = Math.floor d/16
    if c == 'x' 
      n = r
    else 
      n = (r&0x7|0x8)

    n.toString 16

controllers = []

# handles Placing players into two player games
joinGame = (player) ->
  latest = controllers[controllers.length - 1]

  if latest && Object.keys(latest.game.players).length == 1
    # join game with waiting player
    latest.join player
  else
    # create new single player game
    controllers.push new snakeController(player)

  player.socket.emit 'join-client', player.id


# Sockets
io.sockets.on 'connection', (socket) ->
  address = socket.handshake.address
  client_ip = address.address

  # New player joining
  socket.on 'ready',->
    id = generateUUID(client_ip)

    joinGame
      socket: socket
      id: id


express = require 'express'
io = require 'socket.io'
http =  require 'http'
path = require 'path'
utils = require 'lodash'
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

# Sockets
io.sockets.on 'connection', (socket) ->
  address = socket.handshake.address
  client_ip = address.address

  # New player joining
  socket.on 'ready', ->
    id = utils.uniqueId()
    
    # emit joined
    socket.emit 'attach-client', id

    # join game
    snakeController.joinGame
      socket: socket
      id: id


express = require 'express'
http =  require 'http'
path = require 'path'
utils = require 'lodash'
socket = require './socket'
routes = require './routes'
authentication = require './snake/authentication'

GLOBAL.config = 
  JWT_Token: 'SOMETHINGSECRET'

# Static File Routes
paths =
  bower:  express.static path.join(__dirname, '/bower_components')
  public: express.static path.join(__dirname, '/public')

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

app.get '/',                  routes.index
app.get '/partials/(*)',      routes.partial
app.get '/api/leaders',       routes.leaders

# session
app.get  '/authentication', authentication.session
app.post '/authentication', authentication.login
app.del  '/authentication', authentication.logout

# Register
app.post '/register', authentication.register

app.get '*',                  routes.index

# setup server
server = http.createServer(app)

# start server
server.listen app.get('port'), () =>
  console.log('Express server listening on port ' + app.get('port'));

# connet socket.io to server
socket.init server
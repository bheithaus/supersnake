# Services
angular.module 'supersnake.services'

.factory 'Session', ($resource) ->
  $resource '/authentication'

.factory 'User', ($resource) ->
  $resource '/register'

.service 'socket', ($rootScope, UserSession, $state) ->
  # if logged in, send connection attempt, else dont
  socket = if UserSession.loggedIn()
  then io.connect window.location.origin, { query: 'token=' + UserSession.loggedIn() }
  else null

  # if Connection is unauthorized, redirect to home
  if socket
    socket.on 'error', (error) ->
      console.error 'Socket.IO error : ', error
      UserSession.logout()
      $state.transitionTo 'home'

  # after login, do connect
  $rootScope.$watch UserSession.loggedIn, (token) ->
    return unless token
    socket = io.connect window.location.origin, { query: 'token=' + token }

  get: ->
    socket

.service 'UserSession', ($window) ->
  current = $window.sessionStorage.token
  
  session = 
    login: (user) ->
      $window.sessionStorage.token = user.token
      current = user.token

    logout: ->
      delete $window.sessionStorage.token
      current = null

    loggedIn: ->
      current

.factory 'Auth', ($rootScope, Session, UserSession, $state, LoginModal, User, socket) ->
  login: (provider, user, callback) ->
    if typeof callback isnt 'function'
      callback = angular.noop

    Session.save
      provider: provider
      name: user.name
      password: user.password
    , (data) ->
      if not data.error
        # success
        UserSession.login data
        callback()
      else 
        UserSession.logout()
        callback(data.error)

  create: (user, callback) ->
    if typeof callback isnt 'function'
      callback = angular.noop

    User.save user, (data) ->
      UserSession.login data if not data.errors

      callback(data.errors)

  logout: (callback) ->
    if typeof callback isnt 'function'
      callback = angular.noop

    Session.remove () ->
      UserSession.logout()
      if socket.get() and $state.current.name is 'game'
        socket.get().emit 'leavegame'

      callback()

  monitor: () ->
    $rootScope.$on '$stateChangeStart', (event, toState, toParams, fromState, fromParams) ->
      if fromState.name is 'game'
        socket.get().emit 'leavegame'

      if toState.authenticate and not UserSession.loggedIn()
        # User isn’t authenticated
        $state.transitionTo 'home'
        LoginModal.open()
        event.preventDefault()

.factory 'authInterceptor', ($rootScope, $q, $window, $location, UserSession) ->
  request: (config) ->
    config.headers = config.headers or {}
    if UserSession.loggedIn() and config.url.match /^\/api/
      config.headers.Authorization = 'Bearer ' + UserSession.loggedIn()
    
    config

  responseError: (response) ->
    if response.status is 401
      UserSession.logout()
      $location.path '/'

    response or $q.when response

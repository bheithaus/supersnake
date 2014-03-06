# Services
angular.module 'supersnake.services'

.factory 'Session', ($resource) ->
  $resource '/authentication'

.factory 'User', ($resource) ->
  $resource '/register'

.service 'socket', ($rootScope, UserSession) ->
  socket = io.connect window.location.origin, { query: 'token=' + UserSession.loggedIn() }

  $rootScope.$watch UserSession.loggedIn, (token) ->
    socket = io.connect window.location.origin, { query: 'token=' + token }

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
      callback()

  monitor: () ->
    $rootScope.$on '$stateChangeStart', (event, toState, toParams, fromState, fromParams) ->
      if fromState.name is 'game'
        socket.emit 'leavegame'

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

angular.module 'supersnake', [
  'ui.router'
  'ui.bootstrap'
  'ngResource'
  'ngAnimate'
  'supersnake.controllers'
  'supersnake.services'
  'supersnake.directives'
]

.config ($stateProvider, $urlRouterProvider, $locationProvider, $httpProvider) ->
  # re include this when implementing Authentication
  $httpProvider.interceptors.push 'authInterceptor'

  # html location
  $locationProvider.html5Mode true
  # For any unmatched url, redirect to /
  $urlRouterProvider.otherwise '/'

  $stateProvider
    .state 'home',
      url: '/'
      templateUrl: 'partials/home'
      controller: 'HomeCtrl'

    .state 'game',
      url: '/game'
      templateUrl: 'partials/game'
      controller: 'GameCtrl'
      authenticate: true

    .state 'leaderboard',
      url: '/leaderboard'
      templateUrl: 'partials/leaderboard'
      controller: 'leaderboardCtrl'

    .state 'login',
      url: '/login'
      # templateUrl: 'partials/session/login'
      controller: 'LoginCtrl'

    .state 'logout',
      url: '/logout'
      controller: 'LogoutCtrl'

.run ($rootScope, $state, Auth) ->
  Auth.monitor()

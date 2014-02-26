angular.module 'supersnake', [
  'ui.router'
  'ui.bootstrap'
  'ngResource'
  'supersnake.controllers'
  'supersnake.services'
  # 'supersnake.directives'
]

.config ($stateProvider, $urlRouterProvider, $locationProvider, $httpProvider) ->
  # re include this when implementing Authentication
  # $httpProvider.interceptors.push 'authInterceptor'

  # html location
  $locationProvider.html5Mode true
  # For any unmatched url, redirect to /
  $urlRouterProvider.otherwise '/'

  $stateProvider
    .state 'game',
      url: '/'
      templateUrl: 'partials/game'
      controller: 'GameCtrl'

    .state 'leaderboard',
      url: '/leaderboard'
      templateUrl: 'partials/leaderboard'
      controller: 'leaderboardCtrl'

    # .state 'list',
    #   url: '/entities'
    #   templateUrl: 'partials/entity/list'
    #   controller: 'ListCtrl'

    # .state 'show',
    #   url: '/entities/:id'
    #   templateUrl: 'partials/entity/show'
    #   controller: 'ShowCtrl'

    # .state 'login',
    #   # templateUrl: 'partials/session/login'
    #   controller: 'LoginCtrl'

    # .state 'logout',
    #   url: '/logout'
    #   controller: 'LogoutCtrl'



.run ($rootScope, $state) ->
  console.log 'starting angular'

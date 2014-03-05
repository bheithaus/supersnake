# /* Controllers */
angular.module 'supersnake.controllers'

.controller 'AppCtrl', ($scope, LoginModal, RegisterModal, UserSession, Auth, $state) ->
  $scope.register = RegisterModal.open
  $scope.login = LoginModal.open

  $scope.loggedIn = ->
    UserSession.loggedIn()

  $scope.logout = ->
    Auth.logout ->
      $state.transitionTo 'home'
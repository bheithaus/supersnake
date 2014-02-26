# /* Controllers */
angular.module 'supersnake.controllers'

.controller 'LogoutCtrl', ($scope, $http, Auth, $state) ->
  Auth.logout () ->
    $state.transitionTo 'home'

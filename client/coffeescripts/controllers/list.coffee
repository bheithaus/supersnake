# /* Controllers */
angular.module 'supersnake.controllers'

.controller 'HomeCtrl', ($scope, $http, $location, LoginModal, User) ->
  console.log 'welcome home'

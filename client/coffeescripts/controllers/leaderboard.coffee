# /* Controllers */
angular.module 'supersnake.controllers'

.controller 'leaderboardCtrl', ($scope, $http, $location, LoginModal, User) ->
  # handle login modal error here
  $http.get '/api/leaders'
  .success (leaders) ->
    for leader in leaders
      leader.lossCount = leader.gameCount - leader.winCount
    
    $scope.leaders = leaders

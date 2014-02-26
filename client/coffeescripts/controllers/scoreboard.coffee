angular.module 'supersnake.controllers'

.controller 'Scoreboard', ($scope, score) ->
  $document.on 'score-client', ->
    $scope.$apply ->
      for key, val of score.get()
        $scope[key] = val

  $document.on 'update-total-games', ->
    $scope.$apply ->
      $scope.concurrentGames = window.client.concurrentGames

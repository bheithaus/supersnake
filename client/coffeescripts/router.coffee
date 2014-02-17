app = angular.module 'app', []

# # simple class exemple - minification safe
# class MySimpleCtrl

#   @$inject: ['$scope'] 
#   constructor: (@scope) ->
#     # attach viewmodel data to the scope:
#     @scope.demo = 'Simple class demo'
    
#     # expose controller functions to scope
#     angular.extend @scope,
#       clear: @clear

#   # use => to bind function to controller instance
#   clear: =>
#     @scope.demo = ""  

parseMeta = (meta) ->
  total: meta.gC
  wins: meta.wC
  losses: meta.gC - meta.wC
  growth: meta.gr

class MainCtrl
  @$inject: ['$scope'] 

  constructor: ($scope) ->
    $(document).on 'brianscustom', () ->
      $scope.player = angular.extend {}, window.client.player
      angular.extend $scope.player, parseMeta($scope.player.meta)

      $scope.losses = $scope.player.losses

      console.log 'player', $scope.player
      console.log 'scope', $scope

app.controller 'MainCtrl', MainCtrl

# //myApp.directive('myDirective', function() {});
# //myApp.factory('myService', function() {});

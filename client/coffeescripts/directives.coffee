angular.module 'supersnake.directives', []

.directive 'savedForm', ($timeout) ->
  scope:
    formData: '='

  link: ($scope, element, attrs) ->
    $timeout () -> 
      inputs = element.find 'input'

      for input in inputs
        input = angular.element input
        type = input.attr 'type' 
        if type is 'text' or type is 'password'
          $scope.formData[input.attr 'name'] = input.val()

      $scope.$apply()
    , 100

.directive 'onHover', ($timeout, $parse) ->
  restrict: 'A'
  templateUrl: 'partials/directives/onhover'

  link: ($scope, element, attrs) ->
    $scope.prompt = attrs.prompt
    $scope.template = attrs.onHover

    timeoutID = null
    $scope.popped = null
    $scope.active =
      outer: null
      inner: null

    element.on 'mouseover', ->
      $scope.$apply ->
        $scope.enter 'outer'

    element.on 'mouseleave', ->
      $scope.$apply ->
        $scope.leave 'outer'

    $scope.enter = (which) ->
      $scope.active[which] = true
      $scope.popped = true

    $scope.leave = (which) ->
      if $scope.active[which] 
        $scope.active[which] = false

      $scope.hide()

    $scope.hide = ->
      $timeout.cancel timeoutID
      timeoutID = $timeout (-> 
        $scope.popped = if $scope.active.outer or $scope.active.inner
        then true
        else false
      ), 500


    $scope.show = ->
      $scope.popped = true


.directive 'popoverContent', ->
  restrict: 'A'
   # this requires at least angular 1.1.4
  templateUrl: (notsurewhatthisis, attrs)->
    "partials/#{attrs.popoverContent}"

angular.module('app', ['appServices'])
  .config(['$routeProvider', ($routeProvider) ->
    $routeProvider.
      when('/home', {templateUrl: 'home.html',   controller: HomeCtrl}).
      when('/list', {templateUrl: 'list.html',   controller: ListCtrl}).
      when('/detail/:itemId', {templateUrl: 'detail.html',   controller: DetailCtrl}).
      when('/settings', {templateUrl: 'settings.html',   controller: SettingsCtrl}).
      otherwise({redirectTo: '/home'});
  ])


# /* Controllers */

MainCtrl = ($scope, Page) ->
  console.log(Page);
  $scope.page= Page; 


HomeCtrl = ($scope, Page) ->
  Page.setTitle("Welcome");



ListCtrl = ($scope, Page, Model) ->
  Page.setTitle("Items");
  $scope.items = Model.notes();


DetailCtrl = ($scope, Page, Model, $routeParams, $location) ->
  Page.setTitle("Detail")
  id = $scope.itemId = $routeParams.itemId
  $scope.item = Model.get(id)

SettingsCtrl = ($scope, Page) ->
  Page.setTitle("Settings");

# /* Services */

angular.module 'appServices', [] 
  .factory 'Page', ($rootScope) ->
    pageTitle = "Untitled"
    
    page =
      title: () ->
        return pageTitle

      setTitle: (newTitle) ->
        pageTitle = newTitle

  .factory 'Model', () ->
    data = [
      {id:0, title:'Doh', detail:"A dear. A female dear."},
      {id:1, title:'Re', detail:"A drop of golden sun."},
      {id:2, title:'Me', detail:"A name I call myself."},
      {id:3, title:'Fa', detail:"A long, long way to run."},
      {id:4, title:'So', detail:"A needle pulling thread."},
      {id:5, title:'La', detail:"A note to follow So."},
      {id:6, title:'Tee', detail:"A drink with jam and bread."}
    ]

    model =
      notes: () ->
        return data

      get: (id) ->
        return data[id]
      
      add: (note) ->
        currentIndex = data.length
        data.push
          id: currentIndex
          title: note.title
          detail: note.detail

      delete: (id) ->
        oldNotes = data
        data = []
        angular.forEach oldNotes, (note) ->
          data.push(note) if note.id isnt id

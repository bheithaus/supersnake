angular.module('supersnake', ['ui.router', 'ui.bootstrap', 'ngResource', 'supersnake.controllers', 'supersnake.services']).config(function($stateProvider, $urlRouterProvider, $locationProvider, $httpProvider) {
  $httpProvider.interceptors.push('authInterceptor');
  $locationProvider.html5Mode(true);
  $urlRouterProvider.otherwise('/');
  return $stateProvider.state('home', {
    url: '/',
    templateUrl: 'partials/home',
    controller: 'HomeCtrl'
  }).state('game', {
    url: '/game',
    templateUrl: 'partials/game',
    controller: 'GameCtrl',
    authenticate: true
  }).state('leaderboard', {
    url: '/leaderboard',
    templateUrl: 'partials/leaderboard',
    controller: 'leaderboardCtrl'
  }).state('login', {
    url: '/login',
    controller: 'LoginCtrl'
  }).state('logout', {
    url: '/logout',
    controller: 'LogoutCtrl'
  });
}).run(function($rootScope, $state, Auth) {
  return Auth.monitor();
});

var Game, Snake, includes,
  __slice = [].slice;

includes = function(bodyPieces, head) {
  return _(bodyPieces).any(function(piece) {
    return piece[0] === head[0] && piece[1] === head[1];
  });
};

Game = (function() {
  function Game(boardSize, id, snakes, open) {
    this.boardSize = boardSize;
    this.id = id;
    this.open = open;
    this.snakes = this.makeSnakes(snakes);
  }

  Game.prototype.update = function(state) {
    this.updateSnakes(state.s);
    this.food = state.f;
    this.paused = state.p;
    if (state.ate) {
      this.eat(state.ate);
    }
    if (state.e) {
      return this.endGame = state.e;
    }
  };

  Game.prototype.eat = function(id) {
    var growth;
    if (this.id.toString() === id.toString()) {
      growth = window.client.player.meta.growth;
      window.client.player.meta.growth = growth ? growth + 1 : 1;
      return $(document).trigger('score-client');
    }
  };

  Game.prototype.updateSnakes = function(updates) {
    var id, snake, _results;
    _results = [];
    for (id in updates) {
      snake = updates[id];
      _results.push(this.snakes[id].update(snake.h, snake.d, snake.l));
    }
    return _results;
  };

  Game.prototype.makeSnakes = function(snakes) {
    return _(snakes).mapValues((function(_this) {
      return function(snake, id) {
        return new Snake(snake);
      };
    })(this)).value();
  };

  Game.prototype.step = function() {
    var id, snake, _ref, _results;
    _ref = this.snakes;
    _results = [];
    for (id in _ref) {
      snake = _ref[id];
      snake.move();
      _results.push(this.hitEdge(snake));
    }
    return _results;
  };

  Game.prototype.randomCoord = function() {
    var times, _i, _len, _ref, _results;
    _ref = [1, 1];
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      times = _ref[_i];
      _results.push(Math.floor(Math.random() * this.boardSize));
    }
    return _results;
  };

  Game.prototype.hitEdge = function(snake) {
    snake.body[0][0] += this.boundsOneWay(snake.body[0][0]) * this.boardSize;
    return snake.body[0][1] += this.boundsOneWay(snake.body[0][1]) * this.boardSize;
  };

  Game.prototype.boundsOneWay = function(position) {
    if (position < 0) {
      return 1;
    } else if (position >= this.boardSize) {
      return -1;
    } else {
      return 0;
    }
  };

  return Game;

})();

Snake = (function() {
  function Snake() {
    var body;
    body = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    this.body = body;
    this.length = 15;
    this.oldDirection = [1, 0];
    this.direction = [1, 0];
  }

  Snake.prototype.update = function(head, direction, length) {
    this.direction = direction;
    this.length = length;
    this.body.unshift(head);
    if (this.body.length > this.length) {
      return this.body.pop();
    }
  };

  return Snake;

})();

angular.module('supersnake.controllers', []);

var $document, CIRCLE, COLORS, FONTS, PAUSE_PROMPTS, clientController,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

CIRCLE = Math.PI * 2;

$document = $(document);

FONTS = {
  score: "bold 12px sans-serif",
  prompt: "bold 20px zapfino"
};

PAUSE_PROMPTS = {
  self: 'You paused the game',
  other: 'The other player paused the game'
};

COLORS = {
  background: '#E6E6C3',
  players: ['black', 'blue']
};

angular.module('supersnake.controllers').controller('GameCtrl', function($scope, $http, $location, LoginModal, User, socket) {
  $scope.name = 'hey derr';
  socket.emit('ready');
  return socket.on('attach-client', (function(_this) {
    return function(player) {
      var client;
      client = window.client = new clientController(socket, player);
      $document.trigger('score-client');
      socket.on('update-client', client.state);
      socket.on('score-client', function(meta) {
        window.client.player.meta = meta;
        return $document.trigger('score-client');
      });
      return socket.on('update-total-games', function(count) {
        window.client.concurrentGames = count;
        return $document.trigger('update-total-games');
      });
    };
  })(this));
});

clientController = (function() {
  function clientController(socket, player) {
    this.socket = socket;
    this.player = player;
    this.state = __bind(this.state, this);
    this.runStep = __bind(this.runStep, this);
    this.bindKeyDown = __bind(this.bindKeyDown, this);
    this.render = __bind(this.render, this);
    this.canvas = $('canvas');
    this.context = this.canvas[0].getContext('2d');
  }

  clientController.prototype.newGame = function(state, incoming) {
    this.game = new Game(50, this.player.id, state.s, state.o);
    return this.bindKeyDown();
  };

  clientController.prototype.namespace = '.snake';

  clientController.prototype.render = function() {
    this.clear();
    this.drawSnakes();
    this.drawScore();
    this.drawFood();
    if (this.game.open) {
      return this.drawPractice();
    }
  };

  clientController.prototype.translate = function(pos) {
    return 10 * pos + 5;
  };

  clientController.prototype.drawCircle = function(pos, color, head) {
    var radius;
    radius = head ? 6 : 5;
    this.context.beginPath();
    this.context.arc(this.translate(pos[0]), this.translate(pos[1]), radius, 0, CIRCLE, false);
    this.context.fillStyle = color;
    return this.context.fill();
  };

  clientController.prototype.clear = function() {
    return this.context.clearRect(0, 0, 500, 500);
  };

  clientController.prototype.drawPractice = function() {
    this.context.font = FONTS.score;
    this.context.textAlign = "left";
    this.context.fillStyle = 'orange';
    return this.context.fillText('Awaiting player - in Practice Mode', 10, 10);
  };

  clientController.prototype.drawSnakes = function() {
    var id, iterator, piece, snake, _i, _len, _ref, _ref1, _results;
    iterator = 0;
    _ref = this.game.snakes;
    _results = [];
    for (id in _ref) {
      snake = _ref[id];
      _ref1 = snake.body.slice(1);
      for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
        piece = _ref1[_i];
        this.drawCircle(piece, '#435E3B');
      }
      this.drawCircle(snake.body[0], COLORS.players[iterator], true);
      _results.push(iterator++);
    }
    return _results;
  };

  clientController.prototype.drawFood = function() {
    var food, _i, _len, _ref, _results;
    _ref = this.game.food;
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      food = _ref[_i];
      _results.push(this.drawCircle(food, 'red'));
    }
    return _results;
  };

  clientController.prototype.drawScore = function() {
    var id, iterator, snake, _ref, _results;
    this.context.font = FONTS.score;
    this.context.textAlign = "left";
    iterator = 0;
    _ref = this.game.snakes;
    _results = [];
    for (id in _ref) {
      snake = _ref[id];
      this.context.fillStyle = COLORS.players[iterator];
      this.context.fillText("Score: " + snake.body.length, 435, 15 + (15 * iterator));
      _results.push(iterator++);
    }
    return _results;
  };

  clientController.prototype.drawPause = function() {
    return this.drawPrompt(PAUSE_PROMPTS[(this.game.paused === this.player.id ? 'self' : 'other')], "blue", true);
  };

  clientController.prototype.incomingPlayer = function(state) {
    var a, dir, incoming;
    this.started = null;
    a = 0;
    dir = 1;
    incoming = (function(_this) {
      return function() {
        if (_this.started) {
          return console.log('starting');
        }
        a += dir * 0.05;
        dir = a >= 1 ? -1 : a <= 0 ? 1 : dir;
        _this.drawPrompt('Joining new Human vs. Human game', COLORS.background);
        _this.drawPrompt('Joining new Human vs. Human game', 'rgba(0, 20, 200, ' + a + ')');
        return setTimeout(incoming, 60);
      };
    })(this);
    return incoming();
  };

  clientController.prototype.drawPrompt = function(text, color, pause) {
    var x, y;
    x = y = this.game.boardSize * 10 / 2;
    if (pause) {
      y = 100;
    }
    this.context.fillRect('black', x, y, 800, 200);
    this.context.font = FONTS.prompt;
    this.context.textAlign = "center";
    if (color) {
      this.context.fillStyle = color;
    }
    return this.context.fillText(text, x, y);
  };

  clientController.prototype.bindKeyDown = function() {
    $document.off(this.namespace);
    return $document.on('keydown' + this.namespace, (function(_this) {
      return function(event) {
        var code;
        code = event.keyCode;
        if ((36 < code && code < 41) || code === 80 || code === 13) {
          event.preventDefault();
          event.stopPropagation();
          return _this.socket.emit('keypress', code, _this.player.id);
        }
      };
    })(this));
  };

  clientController.prototype.runStep = function(state) {
    var loser, prompt;
    this.game.update(state);
    if (!this.started) {
      this.started = true;
    }
    if (!this.game.endGame) {
      if (this.game.paused) {
        return this.drawPause();
      }
      return this.render();
    } else {
      this.render();
      loser = this.game.endGame;
      prompt = (function() {
        switch (loser) {
          case -2:
            return 'Opponent Quit!';
          case -1:
            return "Tie game";
          case this.player.id:
            return "You Lost";
          default:
            return "You Won";
        }
      }).call(this);
      this.drawPrompt(prompt + "! >--< Press Enter.", "red");
      return this.game.endGame = null;
    }
  };

  clientController.prototype.state = function(state) {
    if (state.n) {
      this.newGame(state);
    }
    if (state.i) {
      return this.incomingPlayer(state);
    }
    return this.runStep(state);
  };

  return clientController;

})();

angular.module('supersnake.controllers').controller('leaderboardCtrl', function($scope, $http, $location, LoginModal, User) {
  return $http.get('/api/leaders').success(function(leaders) {
    var leader, _i, _len;
    console.log(leaders);
    for (_i = 0, _len = leaders.length; _i < _len; _i++) {
      leader = leaders[_i];
      leader.lossCount = leader.gameCount - leader.winCount;
    }
    return $scope.leaders = leaders;
  });
});

angular.module('supersnake.controllers').controller('HomeCtrl', function($scope, $http, $location, LoginModal, User) {
  return console.log('welcome home');
});

angular.module('supersnake.controllers').controller('LoginInstanceCtrl', function($scope, $modalInstance, Auth, $state) {
  $scope.user = {};
  $scope.login = function() {
    return Auth.login('password', {
      name: $scope.user.name,
      password: $scope.user.password
    }, function(error) {
      if (!error) {
        $modalInstance.dismiss();
        return $state.transitionTo('game');
      } else {
        return $scope.error = true;
      }
    });
  };
  return $scope.cancel = function() {
    return $modalInstance.dismiss('cancel');
  };
}).controller('LoginCtrl', function(LoginModal) {
  return LoginModal.open();
});

angular.module('supersnake.controllers').controller('LogoutCtrl', function($scope, $http, Auth, $state) {
  return Auth.logout(function() {
    return $state.transitionTo('home');
  });
});

angular.module('supersnake.controllers').controller('RegisterInstanceCtrl', function($scope, $modalInstance, $state, Auth) {
  $scope.user = {};
  $scope.register = function() {
    return Auth.create($scope.user, function(errors) {
      var error, field, _results;
      if (!errors) {
        $modalInstance.dismiss();
        return $state.transitionTo('home');
      } else {
        _results = [];
        for (field in errors) {
          error = errors[field];
          _results.push($scope[field + '_error'] = error);
        }
        return _results;
      }
    });
  };
  return $scope.cancel = function() {
    return $modalInstance.dismiss('cancel');
  };
}).controller('LoginCtrl', function(LoginModal) {
  return LoginModal.open();
});

angular.module('supersnake.controllers').controller('AppCtrl', function($scope, LoginModal, RegisterModal, UserSession, Auth, $state) {
  $scope.register = RegisterModal.open;
  $scope.login = LoginModal.open;
  $scope.loggedIn = function() {
    return UserSession.loggedIn();
  };
  return $scope.logout = function() {
    return Auth.logout(function() {
      return $state.transitionTo('home');
    });
  };
});

angular.module('supersnake.controllers').controller('Scoreboard', function($scope, score) {
  $document.on('score-client', function() {
    return $scope.$apply(function() {
      var key, val, _ref, _results;
      _ref = score.get();
      _results = [];
      for (key in _ref) {
        val = _ref[key];
        _results.push($scope[key] = val);
      }
      return _results;
    });
  });
  return $document.on('update-total-games', function() {
    return $scope.$apply(function() {
      return $scope.concurrentGames = window.client.concurrentGames;
    });
  });
});

angular.module('supersnake.services', []);

angular.module('supersnake.services').factory('LoginModal', function($modal, $log) {
  return {
    open: function() {
      var modalInstance;
      return modalInstance = $modal.open({
        templateUrl: 'partials/session/login',
        controller: 'LoginInstanceCtrl'
      });
    }
  };
}).factory('RegisterModal', function($modal, $log) {
  return {
    open: function() {
      var modalInstance;
      return modalInstance = $modal.open({
        templateUrl: 'partials/session/register',
        controller: 'RegisterInstanceCtrl'
      });
    }
  };
});

var parseMeta;

angular.module('supersnake.services').service('score', function() {
  return {
    get: function() {
      return parseMeta(window.client.player.meta);
    }
  };
});

parseMeta = function(meta) {
  meta.lossCount = meta.gameCount - meta.winCount || 0;
  return meta;
};

angular.module('supersnake.services').factory('Session', function($resource) {
  return $resource('/authentication');
}).factory('User', function($resource) {
  return $resource('/register');
}).service('socket', function(UserSession) {
  return io.connect(window.location.origin, {
    query: 'token=' + UserSession.loggedIn()
  });
}).service('UserSession', function($window) {
  var current, session;
  current = $window.sessionStorage.token;
  return session = {
    login: function(user) {
      $window.sessionStorage.token = user.token;
      return current = user.token;
    },
    logout: function() {
      delete $window.sessionStorage.token;
      return current = null;
    },
    loggedIn: function() {
      return current;
    }
  };
}).factory('Auth', function($rootScope, Session, UserSession, $state, LoginModal, User) {
  return {
    login: function(provider, user, callback) {
      if (typeof callback !== 'function') {
        callback = angular.noop;
      }
      return Session.save({
        provider: provider,
        name: user.name,
        password: user.password
      }, function(data) {
        console.log(data);
        if (!data.error) {
          UserSession.login(data);
          return callback();
        } else {
          UserSession.logout();
          return callback(data.error);
        }
      });
    },
    create: function(user, callback) {
      if (typeof callback !== 'function') {
        callback = angular.noop;
      }
      return User.save(user, function(data) {
        if (!data.errors) {
          UserSession.login(data);
        }
        return callback(data.errors);
      });
    },
    logout: function(callback) {
      if (typeof callback !== 'function') {
        callback = angular.noop;
      }
      return Session.remove(function() {
        UserSession.logout();
        return callback();
      });
    },
    monitor: function() {
      return $rootScope.$on('$stateChangeStart', function(event, current, prev) {
        if (current.authenticate && !UserSession.loggedIn()) {
          $state.transitionTo('home');
          LoginModal.open();
          return event.preventDefault();
        }
      });
    }
  };
}).factory('authInterceptor', function($rootScope, $q, $window, $location, UserSession) {
  return {
    request: function(config) {
      config.headers = config.headers || {};
      if (UserSession.loggedIn() && config.url.match(/^\/api/)) {
        config.headers.Authorization = 'Bearer ' + UserSession.loggedIn();
      }
      return config;
    },
    responseError: function(response) {
      if (response.status === 401) {
        UserSession.logout();
        $location.path('/');
      }
      return response || $q.when(response);
    }
  };
});

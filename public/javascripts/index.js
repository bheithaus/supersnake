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

clientController = (function() {
  function clientController(socket, player) {
    this.socket = socket;
    this.player = player;
    this.update = __bind(this.update, this);
    this.state = __bind(this.state, this);
    this.runStep = __bind(this.runStep, this);
    this.bindKeyDown = __bind(this.bindKeyDown, this);
    this.render = __bind(this.render, this);
    this.id = this.player.id;
    this.game = new Game(50, this.id);
    this.canvas = $('canvas');
    this.context = this.canvas[0].getContext('2d');
  }

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
    var i, piece, snake, _i, _j, _len, _len1, _ref, _ref1, _results;
    _ref = this.game.snakes;
    _results = [];
    for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
      snake = _ref[i];
      _ref1 = snake.body.slice(1);
      for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
        piece = _ref1[_j];
        this.drawCircle(piece, '#435E3B');
      }
      _results.push(this.drawCircle(snake.body[0], COLORS.players[i], true));
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
    var i, snake, _i, _len, _ref, _results;
    this.context.font = FONTS.score;
    this.context.textAlign = "left";
    _ref = this.game.snakes;
    _results = [];
    for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
      snake = _ref[i];
      this.context.fillStyle = COLORS.players[i];
      _results.push(this.context.fillText("Score: " + snake.body.length, 435, 15 + (15 * i)));
    }
    return _results;
  };

  clientController.prototype.drawPause = function() {
    return this.drawPrompt(PAUSE_PROMPTS[(this.game.paused === this.id ? 'self' : 'other')], "blue", true);
  };

  clientController.prototype.incomingPlayer = function(incoming) {
    var a, dir;
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
          return _this.socket.emit('keypress', code, _this.id);
        }
      };
    })(this));
  };

  clientController.prototype.runStep = function() {
    var incoming, loser, prompt;
    if (this.newState) {
      this.game.update(this.newState);
      incoming = this.newState.incoming;
      this.newState = null;
      if (incoming) {
        return;
      }
    } else {
      this.game.step();
    }
    if (!this.game.endGame) {
      if (this.game.paused) {
        return this.drawPause();
      }
      this.render();
      return this.runLoop();
    } else {
      this.render();
      loser = this.game.endGame;
      prompt = (function() {
        switch (loser) {
          case -2:
            return 'Opponent Quit!';
          case -1:
            return "Tie game";
          case this.id:
            return "You Lost";
          default:
            return "You Won";
        }
      }).call(this);
      this.drawPrompt(prompt + "! >--< Press Enter.", "red");
      return this.game.endGame = null;
    }
  };

  clientController.prototype.newGame = function() {
    this.bindKeyDown();
    this.started = true;
    this.running = true;
    return this.runStep();
  };

  clientController.prototype.state = function(state) {
    this.newState = state;
    if (state.incoming) {
      return this.incomingPlayer();
    }
    if (state.newGame) {
      return this.newGame();
    } else if (this.game.paused) {
      if (state.endGame || !state.paused) {
        return this.runStep();
      }
    }
  };

  clientController.prototype.update = function() {
    this.game.update(this.newState);
    return this.newState = null;
  };

  clientController.prototype.runLoop = function() {
    return this.timeout = window.setTimeout(this.runStep, this.game.stepTime);
  };

  return clientController;

})();

$document.ready(function() {
  var client, socket;
  client = null;
  socket = io.connect(window.location.origin);
  socket.emit('ready');
  return socket.on('attach-client', (function(_this) {
    return function(id) {
      client = window.client = new clientController(socket, id);
      $document.trigger('brianscustom');
      return socket.on('update-client', client.state);
    };
  })(this));
});

var MainCtrl, app, parseMeta;

app = angular.module('app', []);

parseMeta = function(meta) {
  return {
    total: meta.gC,
    wins: meta.wC,
    losses: meta.gC - meta.wC,
    growth: meta.gr
  };
};

MainCtrl = (function() {
  MainCtrl.$inject = ['$scope'];

  function MainCtrl($scope) {
    $(document).on('brianscustom', function() {
      $scope.player = angular.extend({}, window.client.player);
      angular.extend($scope.player, parseMeta($scope.player.meta));
      $scope.losses = $scope.player.losses;
      console.log('player', $scope.player);
      return console.log('scope', $scope);
    });
  }

  return MainCtrl;

})();

app.controller('MainCtrl', MainCtrl);

var Game, Snake, includes,
  __slice = [].slice;

includes = function(bodyPieces, head) {
  return _(bodyPieces).any(function(piece) {
    return piece[0] === head[0] && piece[1] === head[1];
  });
};

Game = (function() {
  function Game(boardSize, id) {
    this.boardSize = boardSize;
    this.id = id;
    this.snakes = this.makeSnakes(2);
  }

  Game.prototype.update = function(state) {
    this.food = state.food;
    this.updateSnakes(state.snakes);
    this.open = state.open;
    this.stepTime = state.stepTime;
    this.paused = state.paused;
    if (state.endGame) {
      return this.endGame = state.endGame;
    }
  };

  Game.prototype.updateSnakes = function(updates) {
    var i, snake, _i, _len, _ref, _results;
    _ref = this.snakes;
    _results = [];
    for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
      snake = _ref[i];
      _results.push(snake.update(updates[i].body, updates[i].oldDirection, updates[i].direction));
    }
    return _results;
  };

  Game.prototype.makeSnakes = function(number) {
    var i, _i, _len, _ref, _results;
    _ref = [1, 1];
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      i = _ref[_i];
      _results.push(new Snake(this.randomCoord()));
    }
    return _results;
  };

  Game.prototype.step = function() {
    var snake, _i, _len, _ref, _results;
    _ref = this.snakes;
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      snake = _ref[_i];
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
    }
    if (position >= this.boardSize) {
      return -1;
    }
    return 0;
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

  Snake.prototype.update = function(body, oldDirection, direction) {
    this.body = body;
    this.oldDirection = oldDirection;
    this.direction = direction;
  };

  Snake.prototype.move = function() {
    this.oldDirection = this.direction;
    this.body.unshift(this.addVector(this.body[0], this.direction));
    if (this.body.length > this.length) {
      return this.body.pop();
    }
  };

  Snake.prototype.eat = function() {
    return this.length += 1;
  };

  Snake.prototype.addVector = function(position, vector) {
    return [position[0] + vector[0], position[1] + vector[1]];
  };

  Snake.prototype.sameCoords = function(c1, c2) {
    return c1[0] === c2[0] && c1[1] === c2[1];
  };

  return Snake;

})();

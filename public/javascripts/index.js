var $document, CIRCLE, FONTS, PAUSE_PROMPTS, clientController,
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

clientController = (function() {
  function clientController(socket, id) {
    this.socket = socket;
    this.id = id;
    this.update = __bind(this.update, this);
    this.runStep = __bind(this.runStep, this);
    this.bindKeyDown = __bind(this.bindKeyDown, this);
    this.game = new Game(50);
    this.canvas = $('canvas');
    this.context = this.canvas[0].getContext('2d');
    this.bindKeyDown();
  }

  clientController.prototype.colors = ['black', 'blue'];

  clientController.prototype.render = function() {
    this.clear();
    this.drawSnakes();
    this.drawScore();
    return this.drawFood();
  };

  clientController.prototype.translate = function(pos) {
    return 10 * pos + 5;
  };

  clientController.prototype.drawCircle = function(pos, color) {
    this.context.beginPath();
    this.context.arc(this.translate(pos[0]), this.translate(pos[1]), 5, 0, CIRCLE, false);
    this.context.fillStyle = color;
    return this.context.fill();
  };

  clientController.prototype.clear = function() {
    return this.context.clearRect(0, 0, 500, 500);
  };

  clientController.prototype.drawSnakes = function() {
    var i, piece, snake, _i, _len, _ref, _results;
    _ref = this.game.snakes;
    _results = [];
    for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
      snake = _ref[i];
      this.drawCircle(snake.body[0], this.colors[i]);
      _results.push((function() {
        var _j, _len1, _ref1, _results1;
        _ref1 = snake.body.slice(1);
        _results1 = [];
        for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
          piece = _ref1[_j];
          _results1.push(this.drawCircle(piece, '#435E3B'));
        }
        return _results1;
      }).call(this));
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
      this.context.fillStyle = this.colors[i];
      _results.push(this.context.fillText("Score: " + snake.length, 435, 15 + (15 * i)));
    }
    return _results;
  };

  clientController.prototype.drawPrompt = function(text, color) {
    this.context.font = FONTS.prompt;
    this.context.textAlign = "center";
    this.context.fillStyle = color;
    return this.context.fillText(text, 250, 250);
  };

  clientController.prototype.bindKeyDown = function() {
    return $document.on('keydown', (function(_this) {
      return function(event) {
        var _ref;
        if ((36 < (_ref = event.keyCode) && _ref < 41) || event.keyCode === 80) {
          return _this.socket.emit('keypress', event.keyCode, _this.id);
        }
      };
    })(this));
  };

  clientController.prototype.pause = function(state) {
    var prompt;
    this.paused = true;
    prompt = PAUSE_PROMPTS[(state.paused === this.id ? 'self' : 'other')];
    return this.drawPrompt(prompt, "blue");
  };

  clientController.prototype.runStep = function() {
    var loser, prompt;
    this.render();
    if (!this.game.over) {
      return this.runLoop();
    } else {
      loser = this.game.over.code;
      prompt = loser === -1 ? "Tie game" : loser === this.id ? "You Lost" : "You Won";
      this.drawPrompt(prompt + "! >--< Click to Restart.", "red");
      return this.game.over = null;
    }
  };

  clientController.prototype.update = function(state) {
    this.game.set(state);
    if (state.paused) {
      return this.pause(state);
    }
  };

  clientController.prototype.reset = function() {};

  clientController.prototype.runLoop = function() {
    return window.setTimeout(this.runStep, this.stepTime());
  };

  clientController.prototype.stepTime = function() {
    return 100;
  };

  return clientController;

})();

$document.ready(function() {
  var client, socket;
  client = null;
  socket = io.connect('http://localhost');
  socket.emit('ready');
  return socket.on('join-client', (function(_this) {
    return function(id) {
      console.log(id);
      client = window.client = new clientController(socket, id);
      socket.on('update-client', client.update);
      return client.runLoop();
    };
  })(this));
});

var Game, Snake, includes,
  __slice = [].slice;

includes = function(bodyPieces, head) {
  return _(bodyPieces).any(function(piece) {
    return piece[0] === head[0] && piece[1] === head[1];
  });
};

Game = (function() {
  function Game(boardSize) {
    this.boardSize = boardSize;
  }

  Game.prototype.set = function(state) {
    this.snakes = state.snakes;
    this.food = state.food;
    if (state.endGame) {
      return this.over = state.endGame;
    }
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

  Game.prototype.collision = function() {
    var bodies, i, losers, snake, _i, _j, _len, _len1, _ref, _ref1;
    bodies = [];
    losers = [];
    _ref = this.snakes;
    for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
      snake = _ref[i];
      bodies = bodies.concat(snake.body.slice(1));
    }
    _ref1 = this.snakes;
    for (i = _j = 0, _len1 = _ref1.length; _j < _len1; i = ++_j) {
      snake = _ref1[i];
      if (includes(bodies, snake.body[0])) {
        losers.push(i + 1);
      }
    }
    return losers;
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

  Snake.prototype.oroborus = function() {
    return _(this.body.slice(1)).contains(this.body[0]);
  };

  Snake.prototype.move = function() {
    var newPosition;
    this.oldDirection = this.direction;
    newPosition = this.addVector(this.body[0], this.direction);
    this.body.unshift(this.addVector(this.body[0], this.direction));
    if (this.body.length > this.length) {
      return this.body.pop();
    }
  };

  Snake.prototype.eat = function() {
    return this.length += 1;
  };

  Snake.prototype.directions = {
    37: [-1, 0],
    38: [0, -1],
    39: [1, 0],
    40: [0, 1]
  };

  Snake.prototype.turn = function(keyCode) {
    var newDirection;
    newDirection = this.directions[keyCode];
    console.log('newDirection', newDirection);
    if (!newDirection) {
      return;
    }
    if (this.sameCoords([0, 0], this.addVector(newDirection, this.oldDirection))) {
      return;
    }
    if (this.sameCoords(newDirection, this.oldDirection)) {
      return;
    }
    this.direction = newDirection;
    return true;
  };

  Snake.prototype.addVector = function(position, vector) {
    return [position[0] + vector[0], position[1] + vector[1]];
  };

  Snake.prototype.sameCoords = function(c1, c2) {
    return c1[0] === c2[0] && c1[1] === c2[1];
  };

  return Snake;

})();

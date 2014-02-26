var Store = require('../store')

/*
 * GET home page.
 */

exports.index = function (req, res) {
  res.render('index', { title: 'SuperSnake' });
};

exports.partial = function (req, res) {
  res.render('partials/' + req.params[0]);
};


exports.leaders = function (req, res) {
  Store.Player.find({})
  .sort({ winCount: -1 })
  .exec(function (err, players) {

    res.json(players)
  })


};
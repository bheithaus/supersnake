mongoose = require 'mongoose'
Schema = mongoose.Schema
mongoose.connect 'mongodb://localhost/players'


db = mongoose.connection
db.on 'error', console.error.bind(console, 'connection error:')

module.exports = new (class Store
  constructor: () ->
    self = @
    db.once 'open', () =>
      console.log 'MongoDB ready'
      @buildModels()

  _schemas: 
    Player:
      pid: String
      gameCount: Number
      winCount: Number
      growth: Number

  buildModels: () ->
    for name, schema of @_schemas
      @[name] = mongoose.model name, (new Schema schema, { strict:true })

  findOrCreate: (id, callback) ->
    @Player.findOne { pid: id }, (err, player) =>
      return callback err if err
      return callback null, player if player

      @Player.create { pid: id }, callback  

)()
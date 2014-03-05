mongoose = require 'mongoose'
Schema = mongoose.Schema
mongoose.connect 'mongodb://localhost/players'
db = mongoose.connection
db.on 'error', console.error.bind(console, 'connection error:')

module.exports =
  user: require './user' 

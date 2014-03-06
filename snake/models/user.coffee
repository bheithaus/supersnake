mongoose = require 'mongoose'
bcrypt = require 'bcrypt'
Schema = mongoose.Schema
SALT_WORK_FACTOR = 10

UserSchema = new Schema
  name:
    type: String
    required: true
    index:
      unique: true

  email:
    type: String
    required: true
    index:
      unique: true

  password:
    type: String
    required: true

  opponent_preference:
    type: String
    default: 'AStarFinder'

  gameCount: 
    type: Number
    default: 0

  winCount: 
    type: Number
    default: 0

  growth: 
    type: Number
    default: 0


UserSchema.pre 'save', (next) ->
  # only hash the password if it has been modified (or is new)
  return next() if not @isModified('password')

  # generate a salt
  bcrypt.genSalt SALT_WORK_FACTOR, (error, salt) =>
    return next error if error

    # hash the password along with our new salt
    bcrypt.hash @password, salt, (error, hash) =>
      return next error if error

      # override the cleartext password with the hashed one
      @password = hash
      next()

UserSchema.methods.comparePassword = (candidatePassword, cb) ->
  console.log candidatePassword, @password
  bcrypt.compare candidatePassword, @password, (error, isMatch) ->
    console.log error, isMatch
    return cb error if error
    cb null, isMatch

module.exports = mongoose.model 'User', UserSchema
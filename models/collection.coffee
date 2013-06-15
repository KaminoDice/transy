###
Article Collection Model
###

mongoose = require('mongoose')
Schema = mongoose.Schema
ObjectId = Schema.ObjectId

Collection = new Schema
  _id: ObjectId
  name: String
  desc: String
  articles: [{ Type: ObjectId, ref: 'Article' }]

module.exports = mongoose.model('Collection', User)
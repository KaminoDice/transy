###
Article Model
###

moment = require('moment')
url = require('url')
mongoose = require('mongoose')
Schema = mongoose.Schema
ObjectId = Schema.ObjectId
Topic = require('./topic')
User= require('./user')

# sub document
Para = new Schema
  en: String
  cn: String
  type: String
  state: Boolean

Article = new Schema
  _id: ObjectId
  creator: { type: ObjectId, ref: 'User' }
#  topic: { type: ObjectId, ref: 'Topic' }
  enTitle: String
  cnTitle: String
  url: String
  author: String
  completion: { type: Number, default: 0, min: 0, max: 100 }
  createTime: { type: Date, default: new Date() }
  updateTime: { type: Date, default: new Date() }
  paraList: [Para]
  annotationList: [String]
  collectCount: { type: Number, default: 0, min: 0 }
  commentCount: { type: Number, default: 0, min: 0 }

# Virtural - urlHost
Article.virtual('urlHost').get ()->
  return url.parse(this.url).hostname

# Getter - createTime
Article.path('createTime').get (time)->
  # return moment(time).add('m', 10).format('YYYY/M/D H:mm')
  return moment(time).fromNow()

# get hot articles
Article.statics.getHot = (num, callback)->
  this
  # .find({ completion: 100 })
  .find()
  .sort({ commentCount: -1, collectCount: -1 })
  .limit(num)
  .exec callback

# get new articles
Article.statics.getNew = (num, callback)->
  this
  # .find({ completion: 100 })
  .find()
  .populate('creator')
  .populate('topic')
  .sort({ createTime: -1 })
  .limit(num)
  .exec callback

# get by id
Article.statics.getById = (articleId, callback)->
  this
  .findById(articleId)
  .populate('creator')
  .exec callback

# get by user
Article.statics.getByUser = (userId, callback)->
  this
  .find({ creator: userId })
  .populate('creator')
  .exec callback

# get by topic
Article.statics.getByTopic = (topicId, callback)->
  this
  .find({ topic: topicId })
  .populate('creator')
  .populate('topic')
  .exec callback

# new
Article.statics.add = (articleId, userId, enTitle, content, articleUrl, author, callback)->
  article = new this
    _id: articleId
    creator: userId
    enTitle: enTitle
    cnTitle: '待译标题'
    url: articleUrl
    author: author
    abstract: ''
    paraList: []

  # slice the paragraph by \n
  paras = content.split('\n')
  for p in paras when p.trim() != ''
    article.paraList.push
      en: p.trim()
      cn: ''
      type: 'text'
      state: false

  article.save callback

# update
Article.statics.edit = (articleId, article, callback)->
  this.update { _id: articleId },
    enTitle: article.enTitle
    cnTitle: article.cnTitle
    author: article.author
    url: article.url
    abstract: article.abstract
    completion: article.completion
    paraList: article.paraList
  , callback

# remove
Article.statics.removeById = (articleId, callback)->
   this.findByIdAndRemove articleId , (err, article)->
     # article count - 1 in Topic
     Topic.reduceArticleCount article.topic, (err)->
       # article count - 1 in User
       User.reduceArticleCount article.creator, callback

Article.statics.addCommentCount = (articleId, callback)->
  this.update { _id: articleId }, { $inc: { commentCount: 1 }}, callback

Article.statics.reduceCommentCount = (articleId, callback)->
  this.update { _id: articleId }, { $inc: { commentCount: -1 }}, callback

module.exports = mongoose.model('Article', Article)

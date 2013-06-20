###
User Controller
###

url = require('url')
EventProxy = require('eventproxy')
User = require('../models/user')
Article = require('../models/article')
Topic = require('../models/topic')
Collect = require('../models/collect')
Comment = require('../models/comment')
mongoose = require('mongoose')
ObjectId = mongoose.Types.ObjectId

# my personal page
exports.articles = (req, res)->
  User
  .findOne({ name: req.params.user })
  .exec (err, u)->
    Article
    .find({ creator: u.id })
    .populate('creator')
    .populate('topic')
    .exec (err, articles)->
      res.render('user/articles', { u: u, articles: articles })

# my love articles
exports.collects = (req, res)->
  User.findOne { name: req.params.user }, (err, u)->
    Collect
    .find({ user: u.id })
    .exec (err, collects)->
      ep = new EventProxy()
      ep.after 'got_article', collects.length, (articles)->
        res.render('user/collects', { u: u, articles: articles })
      for c in collects
        Article
        .findById(c.article)
        .populate('creator')
        .populate('topic')
        .exec (err, article)->
          ep.emit('got_article', article)

# my topics
exports.comments = (req, res)->
  User
  .findOne({ name: req.params.user })
  .exec (err, u)->
    Comment
    .find({ user: u.id })
    .populate('user')
    .populate('article')
    .exec (err, comments)->
      res.render('user/comments', { u: u, comments: comments })

# user setting
exports.setting = (req, res)->
  User
  .findById(req.cookies.user.id)
  .exec (err, u)->
    res.render('user/setting', { u: u })

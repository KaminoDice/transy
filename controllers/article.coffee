###
Article Controller
###

url = require('url')
User = require('../models/user')
Topic = require('../models/topic')
Article = require('../models/article')
Collect = require('../models/collect')
Comment = require('../models/comment')
mongoose = require('mongoose')
ObjectId = mongoose.Types.ObjectId

# show single article
exports.article = (req, res)->
  Article
  .findById(req.params.id)
  .populate('creator')
  .populate('topic')
  .exec (err, article)->
    Comment
    .find({ article: article.id })
    .populate('user')
    .exec (err, comments)->
      if not req.cookies.user
        res.render("article/article", { article: article, comments: comments, isCollect: false })
      else
        Collect.findOne { user: req.cookies.user.id, article: req.params.id }, (err, collect)->
          isCollect = if collect then true else false
          res.render("article/article", { article: article, comments: comments, isCollect: isCollect })

# show add article page
exports.showAdd = (req, res)->
  res.render('article/add_article', { tid: req.params.tid })

# new article
exports.add = (req, res)->
  if req.form.isValid
    article = new Article
      _id: ObjectId()
      creator: req.cookies.user.id
      topic: req.params.tid
      enTitle: req.body.title
      cnTitle: '待译标题'
      url: req.body.url
      urlHost: url.parse(req.body.url).hostname
      author: req.body.author
      completion: 0
      abstract: ''
      createTime: new Date()
      updateTime: new Date()
      paraList: []

    # slice the paragraph by \n
    paras = req.body.content.split('\n')
    for p in paras when p.trim() != ''
      article.paraList.push
        en: p.trim()
        cn: ''
        type: 'text'
        state: false

    article.save (err)->
      if not err
        # topic's article count + 1
        Topic
        .findById(article.topic)
        .exec (err, c)->
          c.articleCount += 1
          c.save (err)->
            # user's article count + 1
            User
            .findById(article.creator)
            .exec (err, u)->
              u.articleCount += 1
              u.save (err)->
            res.redirect("/article/#{article.id}")
      else
        res.redirect('/article/add')
  else
    res.render('article/add_article', { form: req.form })

# show edit page
exports.showEdit = (req, res)->
  Article.findById req.params.id, (err, article)->
    res.render("article/edit_article", { article: article }) 

# update article
exports.edit = (req, res)->
  Article.findById req.params.id, (err, data)->
    a = req.body.article
    data.enTitle = a.enTitle
    data.cnTitle = a.cnTitle
    data.author = a.author
    data.url = a.url
    data.urlHost = url.parse(a.url).hostname
    data.abstract = a.abstract
    data.completion = a.completion
    data.paraList = a.paraList

    data.save (err)->
      if not err
        res.send(200,  result: 1 )
      else
        res.send(500,  result: 0 )

# delete article
exports.delete = (req, res)->
  Article.findById req.params.id , (err, article)->
    article.remove()
    # topic's article count - 1
    Topic
    .findById(article.topic)
    .exec (err, c)->
      c.articleCount -= 1
      c.save (err)->
        # user's article count - 1
        User
        .findById(article.creator)
        .exec (err, u)->
          u.articleCount -= 1
          u.save (err)->
            res.redirect("/u/#{req.cookies.user.name}")

# output article
exports.output = (req, res)->
  Article.findById(req.params.id , (err, data)->
    html = ''
    for p in data.paraList
      switch req.params.mode
        when 'en'
          html += outputHTML(p.type, p.en)
        when 'cn'
          html += outputHTML(p.type, p.cn)
        when 'ec'
          html += outputHTML(p.type, p.en)
          if p.cn != '' and p.type != 'image'
            html += '\n'
            html += outputHTML(p.type, p.cn)
      html += "\n\n"

    res.set('Content-Type', 'text/plain;charset=utf-8')
    res.send(200, html)
  )

# add comment
exports.comment = (req, res)->
  if req.body.content.trim() == ''
    return res.redirect("/article/#{req.params.id}")

  # add comment into Comment
  c = new Comment
    article: req.params.id
    user: req.cookies.user.id
    content: req.body.content.trim()
    createTime: new Date()
  c.save (err)->
    # comment count + 1 in Article
    Article.findById(c.article).exec (err, article)->
      article.commentCount += 1
      article.save (err)->
        # comment count + 1 in User
        User.findById(c.user).exec (err, user)->
          user.commentCount += 1
          user.save (err)->
            res.redirect("/article/#{c.article}")

# remove comment
exports.discomment = (req, res)->
  # remove comment from Comment
  Comment.findById req.params.id, (err, comment)->
    comment.remove (err)->
      # comment count - 1 in Article
      Article.findById comment.article, (err, article)->
        article.commentCount -= 1
        article.save (err)->
          # comment count - 1 in User
          User.findById comment.user, (err, user)->
            user.commentCount -= 1
            user.save (err)->
              res.redirect("/article/#{article.id}")

# collect article
exports.collect = (req, res)->
  # add item into Collect
  collect = new Collect
    user: req.cookies.user.id
    article: req.params.id
    createTime: new Date()
  collect.save (err)->
    # collect count + 1 in User
    User.findById collect.user, (err, user)->
      # user.collectCount = parseInt(user.collectCount) + 1
      user.collectCount += 1
      user.save (err)->
        # collect count + 1 in Article
        Article.findById collect.article, (err, article)->
          article.collectCount += 1
          article.save (err)->
            res.redirect("/article/#{article.id}")

# dis collect article
exports.discollect = (req, res)->
  # remove item into Collect
  Collect.remove { user: req.cookies.user.id, article: req.params.id }, (err)->
    # collect count - 1 in User 
    User.findById req.cookies.user.id, (err, user)->
      user.collectCount -= 1
      user.save (err)->
        # collect count - 1 in Article
        Article.findById req.params.id, (err, article)->
          article.collectCount -= 1
          article.save (err)->
            res.redirect("/article/#{article.id}")

###
Output html
@params {String} type - the type of para
@params
###
outputHTML = (type, content)->
  switch type
    when 'header'
      html = "<h3>#{content}</h3>"
    when 'text'
      html = "<p>#{content}</p>"
    when 'image'
      html = "<p><img scr='#{content}' /></p>"
    when 'quote'
      html = "<blockquote>#{content}</blockquote>"
  html
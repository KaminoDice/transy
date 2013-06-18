###
Article Controller
###

url = require('url')
Article = require('../models/article')
Topic = require('../models/topic')
mongoose = require('mongoose')
ObjectId = mongoose.Types.ObjectId

# show single article
exports.article = (req, res)->
  Article
  .findById(req.params.id)
  .populate('creator')
  .populate('topic')
  .exec (err, data)->
    res.render("article/article", { article: data })

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
      cnTitle: ''
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

    article.save((err)->
      if not err
        # topic's article count + 1
        Topic
        .findById(article.topic)
        .exec (err, c)->
          c.articleCount += 1
          c.save (err)->
            res.redirect("/article/#{article.id}")
      else
        res.redirect('/article/add')
    )
  else
    res.render('article/add_article', { form: req.form })

# show edit page
exports.showEdit = (req, res)->
  Article.findById(req.params.id, (err, data)->
    res.render("article/edit_article",
      article: data 
    )
  )

# update article
exports.edit = (req, res)->
  Article.findById(req.params.id, (err, data)->
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
  )

# delete article
exports.delete = (req, res)->
  Article.remove(_id: req.params.id , (err)->
    if not err
      # topic's article count - 1
      Topic
      .findById(article.topic)
      .exec (err, c)->
        c.articleCount -= 1
        c.save (err)->
          res.redirect("/user/#{req.cookies.user.name}")
    else
      res.redirect('/article/' + req.params.id)
  )

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

# collect article
exports.collect = (req, res)->
  # add item into ArticleCollect
  # article collect count + 1 in User
  # collect count + 1 in Article

# dis collect article
exports.disCollect = (req, res)->
  # remove item into ArticleCollect
  # article collect count - 1 in User 
  # collect count - 1 in Article

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
# global var
g = {
  # save the item be clicked
  clickItem: null 
  
  # time tick create by setTimeout, use to auto save article
  articleObj: null

  # article object grab from the page
  saveTick: 0

  # the selection object created by mouse
  # selectedRange: null
}

# save interval
SAVE_INTERVAL = 60000

# must use window.onload to adjust divider's height again
# because when document is ready, font resource hasn't been ready
# so the height of en and cn may not be precise
# but when window is ready, all resources are ready
$(window).load ->
  # init divider's height
  $('.para').each ->
    adjustHeight($(this))

$ ->
  # init auto save
  g.saveTick = setTimeout(saveArticle, SAVE_INTERVAL)

  # init divider's height
  $('.para').each ->
    adjustHeight($(this))

  # init article objects
  g.articleObj = buildArticleObj()

  # dynamic change divider's height
  $('.en, .cn').keyup ->
    adjustHeight($(this).parent())

  $('.en, .cn').blur ->
    adjustHeight($(this).parent())

  # adjust height when img loaded, use jquery.imageLoaded.js
  imagesLoaded($('.para')).on('progress', (instance, image)->
    adjustHeight($(image.img).parents('.para'))
  )

  # show the focus-flag when hover
  $('.para').mouseover ->
    $('.focus-flag').css('visibility', 'hidden')
    $(this).find('.focus-flag').css('visibility', 'visible')

  # toggle translate state: true or false
  $(document).on 'click', '.ec-divider', (e)->
    divider = e.target

    if $(divider).attr('data-state') == 'false'
      $(divider).attr('data-state', 'true')
    else
      $(divider).attr('data-state', 'false')   

  # save when press save button
  $('.save-btn').click(saveArticle)

  # save when press Ctrl-S
  $(document).keydown (e)->
    if e.ctrlKey and e.which == 83
      e.preventDefault()
      saveArticle()

  # alarm when window close and changes have not been saved
  $(window).on 'beforeunload', ->
    if not isArticleEqual(g.articleObj, buildArticleObj())
      return "更改尚未保存，"

  # para key event
  $(document).on 'keydown', '.para', (e)->
    if $(e.target).hasClass('para')
      para = e.target
    else
      para = $(e.target).parents('.para').first()[0]

    # Ctrl+Enter, switch the state of para
    if e.ctrlKey and e.which == 13
      divider = $(para).find('.ec-divider')
      if divider.attr('data-state') == 'false'
        divider.attr('data-state', 'true')
      else
        divider.attr('data-state', 'false')

    # Tab, the next cn foucs (skip image)
    if e.which == 9
      e.preventDefault()
      next = $(para).nextAll("[data-type!='image']").first().find('.cn')
      next.focus()
      setEndOfContenteditable(next[0])

  # handle context-menu event by delegate
  $(document).on('contextmenu', '.para', (e)->
    # prevent the browser's default context-menu
    e.preventDefault()

    # bind the .para element to global var
    if $(e.target).hasClass('para')
      g.clickItem = e.target
    else
      g.clickItem = $(e.target).parents('.para').first()[0]

    # save the selection object
    # g.selectedRange = document.getSelection().getRangeAt(0)

    # image para should'n display 'switch type' submenu
    if $(g.clickItem).attr('data-type') == 'image'
      $('.context-menu').find('.only-for-text').hide()
    else
      $('.context-menu').find('.only-for-text').show()

    $('.context-menu').css
      top: e.clientY + 2 + 'px'
      left: e.clientX + 2 + 'px'
      display: 'block'
  )

  # hide context menu when click
  $(document).click ->
    $('.context-menu').hide()

  # handle context menu click
  $('.context-menu').click (e)->
    c = $(e.target).attr('class')
    switch c
      when 'header', 'text', 'quote', 'code', 'list'
        $(g.clickItem).attr('data-type', c)
        adjustHeight($(g.clickItem))

      when 'up', 'down'
        # remove all the textareas exist in the page
        $('.new-para-wap').detach()

        # add textarea
        textareaHTML = """
          <div class='new-para-wap clearfix'>
            <textarea class='new-para-textarea' placeholder='文本 / 图片地址' rows=4></textarea>
            <div class='btn-wap'>
              <button class='ok-btn' title='确定'><i class='icon-checkmark' /></button>
              <button class='cancel-btn' title='取消'><i class='icon-cancel-2' /></button>
            </div>
          </div>
        """
        if c == 'up'
          $(g.clickItem).before(textareaHTML)
        else
          $(g.clickItem).after(textareaHTML)

        # insert new para
        $('.new-para-textarea').focus()
        $('.ok-btn').click ->
          addContent = $('.new-para-textarea').val().trim()
          if addContent == ""
            return $('.new-para-wap').detach()

          # image
          if addContent.match(/\b(http|https):\/\//) and addContent.match(/.(gif|png|jpeg|jpg|jpeg|bmp)\b/)
            imageHTML = geneParaHTML('image', addContent)
            if c == 'up'
              $(g.clickItem).before(imageHTML)
              imagesLoaded $(g.clickItem).prev(), ->
                adjustHeight($(g.clickItem).prev())
            else
              $(g.clickItem).after(imageHTML)
              imagesLoaded $(g.clickItem).next(), ->
                adjustHeight($(g.clickItem).next())            
          else  # text
            textHTML = geneParaHTML('text', addContent)
            if c == 'up'
              $(g.clickItem).before(textHTML)
              adjustHeight($(g.clickItem).prev())
            else
              $(g.clickItem).after(textHTML)
              adjustHeight($(g.clickItem).next())

          $('.new-para-wap').detach()

        # cancel
        $('.cancel-btn').click ->
          $('.new-para-wap').detach()

      when 'remove-para'
        $(g.clickItem).detach()
      # when 'add-annotation'
      #   if g.selectedRange.collapsed
      #     annotationTag = document.createElement('img')
      #     annotationTag.className = 'annotation'
      #     annotationTag.src = 'http://cdn4.iconfinder.com/data/icons/pictype-free-vector-icons/16/chat-128.png'
      #     g.selectedRange.insertNode(annotationTag)

###
Generate new para HTML code
@method geneParaHTML
@params {String} content - the content of new para
###
geneParaHTML = (type, content)->
  if type == 'image'
    html = """
      <div data-type='image' class='para clearfix'>
        <div class='en'><img src='#{content}' /></div
        ><div class='ec-divider' data-state='true'></div
        ><div class='cn'><img src='#{content}' /></div>
      </div>
    """
  else if type == 'text'
    html = """
      <div data-type='text' class='para clearfix'>
        <div class='en' contenteditable='true'>#{content}</div
        ><div class='ec-divider' data-state='false'></div
        ><div class='cn' contenteditable='true'></div>
      </div>
    """

###
Save article, triggle when click the save btn, or press Ctrl-S
@method saveArticle
###
saveArticle = ->
  clearTimeout(g.saveTick)

  # if not modify, init the next save, then quit
  currArticleObj = buildArticleObj()
  if isArticleEqual(g.articleObj, currArticleObj)
    g.saveTick = setTimeout(saveArticle, SAVE_INTERVAL)
    showSaveState()
    hideSaveState()
    return

  # else save it
  showSaveState()
  g.articleObj = currArticleObj

  # post
  articleId = $('.title').data('article-id')
  $.ajax
    url: "/article/#{articleId}/edit"
    method: 'POST'
    data:
      article: g.articleObj
    success: (data)->
      if data.result == 1
        hideSaveState()
        g.saveTick = setTimeout(saveArticle, SAVE_INTERVAL)

###
Show save state
@method showSaveState
###
showSaveState = ->
  $('.save-state .state-waiting').show()
  $('.save-state .state-ok').hide()
  $('.save-state').animate({ top: '-32px', 200 })

###
Hide save state
@method hideSaveState
###
hideSaveState = ->
  $('.save-state .state-waiting').hide()
  $('.save-state .state-ok').show()
  setTimeout("$('.save-state').animate({top: '0px'}, 200)", 1000)  

###
Whether the two object is equal
@method isArticleEqual
@param {Object} articleA - the article Object A
@param {Object} articleA - the article Object B
@return {Boolen} true means equal, false not
###
isArticleEqual = (articleA, articleB)->
  return JSON.stringify(articleA).length == JSON.stringify(articleB).length

###
Build article object from the page
@method buildArticleObj
@return {Object} the article object
###
buildArticleObj = ->
  article = 
    enTitle: $('.en-title').val().trim()
    cnTitle: $('.cn-title').val().trim()
    author: $('.author').val().trim()
    url: $('.url').val().trim()
    paraList: []

  $('.para').each ->
    type = $(this).attr('data-type')
    
    if type == 'image'
      en = $(this).find('.en img').attr('src')
      cn = en
    else
      en = $(this).find('.en').text().trim()
      cn = $(this).find('.cn').text().trim()

    if $(this).find('.ec-divider').attr('data-state') == 'true'
      state = true
    else
      state = false

    article.paraList.push
      en: en
      cn: cn
      type: type
      state: state

  # compute translate completion, by char num
  totalChar = 0
  completeChar = 0
  for p in article.paraList 
    totalChar += p.en.length
    if p.state
      completeChar += p.en.length
  article.completion = Math.ceil(completeChar / totalChar * 100)

  return article

###
Dynamic change the height of the divider bar
@method adjustHeight
@param {DOM Div Element} para - the div element has class 'para'
###
adjustHeight = (para)->
  enHeight = para.find('.en').innerHeight()
  cnHeight = para.find('.cn').innerHeight()
  dvHeight = if enHeight > cnHeight then enHeight else cnHeight    
  para.find('.ec-divider').css('height', dvHeight + 15 + 'px')

###
Move blink to the end of a ccontenteditable element, see also:
http://stackoverflow.com/questions/1125292/how-to-move-cursor-to-end-of-contenteditable-entity/3866442#3866442
@method setEndOfContenteditable
@params {DOM Element} element - contenteditable DOM Element
###
setEndOfContenteditable = (element)->
  if document.createRange # Firefox, Chrome, Opera, Safari, IE 9+
    range = document.createRange()
    range.selectNodeContents(element)
    range.collapse(false)
    selection = window.getSelection()
    selection.removeAllRanges()
    selection.addRange(range)
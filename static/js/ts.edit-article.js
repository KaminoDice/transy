// Generated by CoffeeScript 1.6.1
var SAVE_INTERVAL, adjustHeight, articleObj, buildArticleObj, clickItem, hideSaveState, isArticleEqual, moveEnd, saveArticle, saveTick, selectedRange, showSaveState;

clickItem = null;

articleObj = null;

saveTick = 0;

selectedRange = null;

SAVE_INTERVAL = 60000;

$(window).load(function() {
  return $('.para').each(function() {
    return adjustHeight($(this));
  });
});

$(function() {
  saveTick = setTimeout(saveArticle, SAVE_INTERVAL);
  $('.para').each(function() {
    return adjustHeight($(this));
  });
  articleObj = buildArticleObj();
  $('.en, .cn').keyup(function() {
    return adjustHeight($(this).parent());
  });
  $('.en, .cn').blur(function() {
    return adjustHeight($(this).parent());
  });
  imagesLoaded($('.para')).on('progress', function(instance, image) {
    return adjustHeight($(image.img).parents('.para'));
  });
  $('.para').mouseover(function() {
    $('.focus-flag').css('visibility', 'hidden');
    return $(this).find('.focus-flag').css('visibility', 'visible');
  });
  $(document).on('click', '.ec-divider', function(e) {
    var divider;
    divider = e.target;
    if ($(divider).attr('data-state') === 'false') {
      return $(divider).attr('data-state', 'true');
    } else {
      return $(divider).attr('data-state', 'false');
    }
  });
  $('.save-btn').click(saveArticle);
  $(document).keydown(function(e) {
    if (e.ctrlKey && e.which === 83) {
      e.preventDefault();
      return saveArticle();
    }
  });
  $(window).on('beforeunload', function() {
    if (!isArticleEqual(articleObj, buildArticleObj())) {
      return "更改尚未保存，";
    }
  });
  $(document).on('keydown', '.para', function(e) {
    var divider, para;
    if ($(e.target).hasClass('para')) {
      para = e.target;
    } else {
      para = $(e.target).parents('.para').first()[0];
    }
    if (e.ctrlKey && e.which === 13) {
      divider = $(para).find('.ec-divider');
      if (divider.attr('data-state') === 'false') {
        divider.attr('data-state', 'true');
      } else {
        divider.attr('data-state', 'false');
      }
    }
    if (e.which === 9) {
      e.preventDefault();
      return $(para).nextAll("[data-type!='image']").first().find('.cn').focus();
    }
  });
  $(document).on('contextmenu', '.para', function(e) {
    e.preventDefault();
    if ($(e.target).hasClass('para')) {
      clickItem = e.target;
    } else {
      clickItem = $(e.target).parents('.para').first()[0];
    }
    selectedRange = document.getSelection().getRangeAt(0);
    if ($(clickItem).attr('data-type') === 'image') {
      $('.context-menu').find('.only-for-text').hide();
    } else {
      $('.context-menu').find('.only-for-text').show();
    }
    return $('.context-menu').css({
      top: e.clientY + 2 + 'px',
      left: e.clientX + 2 + 'px',
      display: 'block'
    });
  });
  $(document).click(function() {
    return $('.context-menu').hide();
  });
  return $('.context-menu').click(function(e) {
    var annotationTag, c;
    c = $(e.target).attr('class');
    switch (c) {
      case 'header':
      case 'text':
      case 'quote':
      case 'code':
        $(clickItem).attr('data-type', c);
        return adjustHeight($(clickItem));
      case 'add-para':
        $(clickItem).after("<textarea class='add-content-wap' placeholder='文本 / 图片地址' rows=4></textarea>");
        return $('.add-content-wap').focus().blur(function() {
          var addContent;
          addContent = $(this).val().trim();
          if (addContent === "") {
            return $(this).detach();
          }
          if (addContent.match(/\bhttp:\/\//) && addContent.match(/.(gif|png|jpeg|jpg|bmp)\b/)) {
            $(clickItem).after("<div data-type='image' class='para clearfix'>\n  <div class='en'>\n    <img src='" + addContent + "' /></div\n  ><div class='ec-divider' data-state='true'></div\n  ><div class='cn'>\n    <img src='" + addContent + "' />\n  </div>\n</div>");
            imagesLoaded($(clickItem).next(), function() {
              return adjustHeight($(clickItem).next());
            });
          } else {
            $(clickItem).after("<div data-type='text' class='para clearfix'>\n  <div class='en' contenteditable='true'>" + addContent + "</div\n  ><div class='ec-divider' data-state='false'></div\n  ><div class='cn' contenteditable='true'></div>\n</div>");
            adjustHeight($(clickItem).next());
          }
          return $(this).detach();
        });
      case 'remove-para':
        return $(clickItem).detach();
      case 'add-annotation':
        if (selectedRange.collapsed) {
          annotationTag = document.createElement('img');
          annotationTag.className = 'annotation';
          annotationTag.src = 'http://cdn4.iconfinder.com/data/icons/pictype-free-vector-icons/16/chat-128.png';
          return selectedRange.insertNode(annotationTag);
        }
    }
  });
});

/*
Save article, triggle when click the save btn, or press Ctrl-S
@method saveArticle
*/


saveArticle = function() {
  var articleId, currArticleObj;
  clearTimeout(saveTick);
  currArticleObj = buildArticleObj();
  if (isArticleEqual(articleObj, currArticleObj)) {
    saveTick = setTimeout(saveArticle, SAVE_INTERVAL);
    showSaveState();
    hideSaveState();
    return;
  }
  showSaveState();
  articleObj = currArticleObj;
  articleId = $('.title').data('article-id');
  return $.ajax({
    url: "/article/" + articleId + "/edit",
    method: 'POST',
    data: {
      article: articleObj
    },
    success: function(data) {
      if (data.result === 1) {
        hideSaveState();
        return saveTick = setTimeout(saveArticle, SAVE_INTERVAL);
      }
    }
  });
};

/*
Show save state
@method showSaveState
*/


showSaveState = function() {
  $('.save-state .state-waiting').show();
  $('.save-state .state-ok').hide();
  return $('.save-state').animate({
    right: '32px',
    200: 200
  });
};

/*
Hide save state
@method hideSaveState
*/


hideSaveState = function() {
  $('.save-state .state-waiting').hide();
  $('.save-state .state-ok').show();
  return setTimeout("$('.save-state').animate({right: '0px'}, 200)", 1000);
};

/*
Whether the two object is equal
@method isArticleEqual
@param {Object} articleA - the article Object A
@param {Object} articleA - the article Object B
@return {Boolen} true means equal, false not
*/


isArticleEqual = function(articleA, articleB) {
  return JSON.stringify(articleA).length === JSON.stringify(articleB).length;
};

/*
Build article object from the page
@method buildArticleObj
@return {Object} the article object
*/


buildArticleObj = function() {
  var article, completeChar, p, totalChar, _i, _len, _ref;
  article = {
    enTitle: $('.en-title').val().trim(),
    cnTitle: $('.cn-title').val().trim(),
    author: $('.author').val().trim(),
    url: $('.url').val().trim(),
    paraList: []
  };
  $('.para').each(function() {
    var cn, en, state, type;
    type = $(this).attr('data-type');
    if (type === 'image') {
      en = $(this).find('.en img').attr('src');
      cn = en;
    } else {
      en = $(this).find('.en').text().trim();
      cn = $(this).find('.cn').text().trim();
    }
    if ($(this).find('.ec-divider').attr('data-state') === 'true') {
      state = true;
    } else {
      state = false;
    }
    return article.paraList.push({
      en: en,
      cn: cn,
      type: type,
      state: state
    });
  });
  totalChar = 0;
  completeChar = 0;
  _ref = article.paraList;
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    p = _ref[_i];
    totalChar += p.en.length;
    if (p.state === true) {
      completeChar += p.en.length;
    }
  }
  article.completion = Math.ceil(completeChar / totalChar * 100);
  return article;
};

/*
Dynamic change the height of the divider bar
@method adjustHeight
@param {DOM Div Element} para - the div element has class 'para'
*/


adjustHeight = function(para) {
  var cnHeight, dvHeight, enHeight;
  enHeight = para.find('.en').innerHeight();
  cnHeight = para.find('.cn').innerHeight();
  dvHeight = enHeight > cnHeight ? enHeight : cnHeight;
  return para.find('.ec-divider').css('height', dvHeight + 15 + 'px');
};

/*
Focus input/textarea/contenteditable, and move blink to the end
@method moveEnd
@params {DOM Element} obj - input/textarea/contenteditable DOM Element
*/


moveEnd = function(obj) {
  var len, sel;
  obj.focus();
  len = obj.innerHTML.length;
  alert(len);
  if (document.selection) {
    sel = obj.createTextRange();
    sel.moveStart('character', len);
    sel.collapse();
    return sel.select();
  } else if (typeof obj.selectionStart === 'number' && typeof obj.selectionEnd === 'number') {
    obj.selectionStart = len;
    return obj.selectionEnd = len;
  }
};

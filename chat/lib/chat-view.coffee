{$, ScrollView, View, TextEditorView} = require 'atom-space-pen-views'
{CompositeDisposable, TextEditor, TextBuffer} = require 'atom'
MessageView = require './message-view'
#_ = require 'underscore-plus'
#socket = require('socket.io-client')('https://atom-chat-server.herokuapp.com');

module.exports =
  class chatView extends ScrollView
    panel = null

    @content: ->
      chatEditor = new TextEditor
        mini: true
        tabLength: 2
        softTabs: true
        softWrapped: true
        buffer: new TextBuffer
        placeholderText: 'Type here'

      @div class: 'chat', =>
        @div class: 'chat-class', =>
          @div class: 'chat-header list-inline tab-bar inset-panel', =>
            @div "Chat", class: 'chat-title', outlet: 'title'
          @div class: 'chat-input', =>
            @subview 'chatEditor', new TextEditorView(editor: chatEditor)
          @div class: 'chat-messages', outlet: 'messages', =>
            @ul tabindex: -1, outlet: 'list'
        @div class: 'chat-resize-handle', outlet: 'resizeHandle'

    initialize: () ->
      @subscriptions = new CompositeDisposable
      @username = atom.config.get('chat.username')
#      @handleSockets()
      @showTitle()
      @handleEvents()
      @room = 0

#    handleSockets: ->
#      socket.on 'connect', =>
#        socket.emit 'atom:user', @username, (id) =>
#          @uuid = id
#          if @username is "User"
#            @username = "User"+@uuid

#      socket.on 'atom:message', (message) =>
#        @addMessage(message)

#      socket.on 'atom:online', (online) =>
#        @showOnline(online)


    handleEvents: ->
      @on 'dblclick', '.chat-resize-handle', =>
        @resizeToFitContent()
      @on 'mousedown', '.chat-resize-handle', (e) => @resizeStarted(e)
      @on 'keyup', '.chat-input .editor', (e) => @enterPressed(e)
      @on 'click', '.chat-room', => @roomsClicked()

      @subscriptions.add atom.config.onDidChange 'chat.showOnRightSide', ({newValue}) =>
        @onSideToggled(newValue)

      @subscriptions.add atom.config.onDidChange 'chat.username', ({newValue}) =>
        if newValue is "User"
          @username = newValue+@uuid
        else
          @username = newValue
        socket.emit 'atom:username', @username

    resizeToFitContent: ->
# set the width as 1
      @width(1)
# make the width of the list as 1
      @width(@list.outerWidth())

    enterPressed: (e) ->
# make key as a specific key code
      key = e.keyCode || e.which
# if we enter 13 as key, then call sendMessage.
      if key == 13
        @sendMessage()
# activate the file
    resizeStarted: =>
      $(document).on('mousemove', @resizeChatView)
      $(document).on('mouseup', @resizeStopped)
# stope the file
    resizeStopped: =>
      $(document).off('mousemove', @resizeChatView)
      $(document).off('mouseup', @resizeStopped)

    resizeChatView: ({pageX, which}) =>
      return @resizeStopped() unless which is 1
      if atom.config.get('chat.showOnRightSide') # set the condition is that if the content show on the right side
        width = @outerWidth() + @offset().left - pageX # set the width
      else # content show on the other sides
        width = pageX - @offset().left # set the width
      @width(width)# store the width

    onSideToggled: (newValue) ->
      @element.dataset.showOnRightSide = newValue
      if @isVisible()
        @detach()
        @attach()

#    showOnline: (online)->
#      @toolTipDisposable?.dispose()
#      @title.html('MonsterBrain Chat')
#      title = "#{_.pluralize(online, 'user')} online"
#      @toolTipDisposable = atom.tooltips.add @title, title: title

# show the title which is "the best team chat ever!!!"
    showTitle: () ->
      @toolTipDisposable?.dispose()
      @title.html('MonsterBrain Chat')
      title = "The best team chat ever!!!"
      @toolTipDisposable = atom.tooltips.add @title, title: title

#  add new message in the list
    addMessage: (message)->
      @list.prepend new MessageView(message)
      if atom.config.get('chat.openOnNewMessage')
        unless @isVisible()
          @detach()
          @attach()

    sendMessage: ->
# make msg is content in chatEditor
      msg = @chatEditor.getText()
      @chatEditor.setText('')
# in text: show msg which should be the content in chatEditor
# uuid: shows the uuid we input
# username: shows the username we input
      message =
        text: msg
        uuid: @uuid
        username: @username

#      socket.emit 'atom:message', message
      @addMessage(message)

#    getSocket: ->
#      socket

    getUserId: ->
      @uuid

    serialize: ->

    destroy: ->
      @detach()
      @subscriptions?.dispose()
      @subscriptions = null
      @toolTipDisposable?.dispose()

    toggle: ->
      if @isVisible()
        @detach()
      else
        @show()

    show: ->
      @attach()
      @focus()

    attach: ->
      if atom.config.get('chat.showOnRightSide')
        @removeClass('panel-left')
        @panel = atom.workspace.addRightPanel(item: this, className: 'panel-right')
      else
        @removeClass('panel-right')
        @panel = atom.workspace.addLeftPanel(item: this, className: 'panel-left')
      @chatEditor.focus()

    detach: ->
      @panel?.destroy()
      @panel = null
      @unfocus()

    unfocus: ->
      atom.workspace.getActivePane().activate()

    deactivate: ->
      @subscriptions.dispose()
      @detach() if @panel?

    detached: ->
      @resizeStopped()

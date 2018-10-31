{$, ScrollView, View, TextEditorView} = require 'atom-space-pen-views'
{CompositeDisposable, TextEditor, TextBuffer} = require 'atom'
MessageView = require './message-view'
fs = require 'fs-plus'
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
      @filePath = atom.config.get('chat.logFile')
#      @handleSockets()
      @openLogFile()
      @showTitle()
      @handleEvents()

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

    openLogFile: =>
      now = new Date
      time = now.getTime()
      str = "______________________________\n\rNEW SESSION (Time: " + time + ")\n\r"
      fs.writeFile(@filePath, str, {flag: "a"}, (err) ->
        if err
          throw err
      )

    handleEvents: ->
      @on 'dblclick', '.chat-resize-handle', =>
        @resizeToFitContent()
      @on 'mousedown', '.chat-resize-handle', (e) => @resizeStarted(e)
      @on 'keyup', '.chat-input .editor', (e) => @enterPressed(e)

      @subscriptions.add atom.config.onDidChange 'chat.showOnRightSide', ({newValue}) =>
        @onSideToggled(newValue)

      @subscriptions.add atom.config.onDidChange 'chat.username', ({newValue}) =>
        @username = newValue
#        socket.emit 'atom:username', @username

      @subscriptions.add atom.config.onDidChange 'chat.logFile', ({newValue}) =>
        @filePath = newValue
#        @openLogFile()

    resizeToFitContent: ->
      @width(1)
      @width(@list.outerWidth())

    enterPressed: (e) ->
      key = e.keyCode || e.which
      if key == 13
        @sendMessage()

    resizeStarted: =>
      $(document).on('mousemove', @resizeChatView)
      $(document).on('mouseup', @resizeStopped)

    resizeStopped: =>
      $(document).off('mousemove', @resizeChatView)
      $(document).off('mouseup', @resizeStopped)

    resizeChatView: ({pageX, which}) =>
      return @resizeStopped() unless which is 1
      if atom.config.get('chat.showOnRightSide')
        width = @outerWidth() + @offset().left - pageX
      else
        width = pageX - @offset().left
      @width(width)

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

    showTitle: () ->
      @toolTipDisposable?.dispose()
      @title.html('MonsterBrain Chat')
      title = "The best team chat ever!!!"
      @toolTipDisposable = atom.tooltips.add @title, title: title

    addMessage: (message) ->
      @list.prepend new MessageView(message)
      utter = new SpeechSynthesisUtterance(message.text)
      window.speechSynthesis.speak(utter)
      if atom.config.get('chat.openOnNewMessage')
        unless @isVisible()
          @detach()
          @attach()

    writeLog: (message) ->
      msg = message.username + ": " + message.text + "\n\r"
      fs.writeFile(@filePath, msg, {flag: "a"}, (err) ->
        if err
          throw err
      )

    sendMessage: ->
      msg = @chatEditor.getText()
      @chatEditor.setText('')
      message =
        text: msg
        uuid: @uuid
        username: @username

#      socket.emit 'atom:message', message
      @addMessage(message)
      @writeLog(message)

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

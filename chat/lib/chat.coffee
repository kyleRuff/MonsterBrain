{CompositeDisposable} = require 'atom'

module.exports =
  activate: (state) ->
    @subscriptions = new CompositeDisposable

    @createView()
    @subscriptions.add atom.commands.add 'atom-workspace', "chat:toggle", =>
      @chatView.toggle()

  createView: ->
    unless @chatView?
      ChatView = require './chat-view'
      @chatView = new ChatView()
    @chatView

  deactivate: ->
    @chatView.deactivate()
    @subscriptions?.dispose()
    @subscriptions = null

  serialize: ->
    chatViewState: @chatView.serialize()

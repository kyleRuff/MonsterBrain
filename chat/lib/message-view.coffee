{$, View} = require 'atom-space-pen-views'

module.exports =
class MessageView extends View
  @content: (message) ->#set the massage in the content
    @li class: 'file entry list-item', =>
      @div class: 'message', =>
        @span class: 'user', "#{message.username}: "
        @span class: 'text', "#{message.text}"

  initialize: () ->

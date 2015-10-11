{CompositeDisposable} = require 'atom'

module.exports = LazyUnityHelper =
  subscriptions: null
  inheritedFilesSelectListView: null

  activate: (state) ->
    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 
      'lazy-unity-helper:insert-inherited-functions': => 
        @createInheritedFilesSelectView().insertInheritedFunctions()

  deactivate: ->
    @subscriptions.dispose()
    if @inheritedFilesSelectListView?
      @inheritedFilesSelectListView.destroy()
      @inheritedFilesSelectListView = null
    
  createInheritedFilesSelectView: ->
    unless @inheritedFilesSelectListView?
      InheritedFilesSelectListView = require './inherited-files-select-list-view.coffee'
      @inheritedFilesSelectListView = new InheritedFilesSelectListView()
    @inheritedFilesSelectListView

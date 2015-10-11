{CompositeDisposable} = require 'atom'

module.exports = LazyUnityHelper =
  subscriptions: null
  inheritedFilesSelectListView: null

  activate: (state) ->
    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    @subscriptions.add atom.commands.add 'atom-workspace', 
      'lazy-unity-helper:insert-inherited-functions': => 
        # function overview: (this is tested for c# only)
        # 1. does a regex search for the base class name
        # 2. searches project for files with 'public BaseClassName '
        # 3. if files.length == 1, use that file otherwise present user list of files to choose
        # 4. regex search for all virtual / override functions
        # 5. insert them where the user cursor is
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

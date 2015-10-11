{CompositeDisposable} = require 'atom'

module.exports = LazyUnityHelper =
  subscriptions: null
  inheritedFilesSelectListView: null
  jumpToDefinitionView: null

  activate: (state) ->
    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    @subscriptions.add atom.commands.add 'atom-workspace', 
      'lazy-unity-helper:insert-inherited-functions': => 
        # Function Overview: (this works / is tested for c# only)
        # 1. does a regex search for the base class name
        # 2. searches project for files with 'public BaseClassName '
        # 3. if files.length == 1, use that file otherwise present user list of files to choose
        # 4. regex search for all virtual / override functions
        # 5. insert them where the user cursor is
        @createInheritedFilesSelectView().insertInheritedFunctions()
      'lazy-unity-helper:jump-to-definition': => 
        # Function Overview: (this works / is tested for c# only)
        # 1. verifies that the current word under cursor looks like a function
        # 2. makes a regex pattern that matches methods with same # of params and name
        # 3. find all matches in all files found and the row index
        # 4. if only one match, use that match otherwise present user with list of matches
        # 5. go to that filePath / that row index
        @createJumpToDefinitionView().jumpToDefinition()

  deactivate: ->
    @subscriptions.dispose()
    if @inheritedFilesSelectListView?
      @inheritedFilesSelectListView.destroy()
      @inheritedFilesSelectListView = null
    if @jumpToDefinitionView?
      @jumpToDefinitionView.destroy()
      @jumpToDefinitionView = null
    
  createInheritedFilesSelectView: ->
    unless @inheritedFilesSelectListView?
      InheritedFilesSelectListView = require './inherited-files-select-list-view.coffee'
      @inheritedFilesSelectListView = new InheritedFilesSelectListView()
    @inheritedFilesSelectListView
    
  createJumpToDefinitionView: ->
    unless @jumpToDefinitionView?
      JumpToDefinitionView = require './jump-to-definition-view.coffee'
      @jumpToDefinitionView = new JumpToDefinitionView()
    @jumpToDefinitionView

path = require 'path'
{File, Point} = require 'atom'
LazyUnityHelperView = require './lazy-unity-helper-view.coffee'

module.exports =
class JumpToDefinitionView extends LazyUnityHelperView
  #region mark - LOGIC
  
  jumpToDefinition: ->
    editor = atom.workspace.getActiveTextEditor()
    currentWord = editor.getWordUnderCursor()
    currentRow = editor.getCursorBufferPosition().row
    currentLineText = editor.lineTextForBufferRow(currentRow)
    
    functionUsedPattern = ///
      ^.*?              # anything from the start of the line (non greedy)
      (#{currentWord})  # capture function name (current word under cursor)
      \x20*             # any number of spaces
      \(([^\)]+)\)      # capture everything inside parens
      ///
      
    try 
      [_, functionName, functionParameters] = currentLineText.match(functionUsedPattern)
    catch error
      atom.notifications.addError("Failed to get values for function: " + currentWord, {dismissable: true})
      return
    
    parameterStrings = ("[^,]+" for parameter in functionParameters.split(','))
    parametersPatternString = parameterStrings.reduceRight((x, y) -> x + ", " + y)
    
    functionDeclarationPattern = ///
      #{functionName}                   # functionName 
      \x20*                             # any number of spaces
      \(#{parametersPatternString}\)    # (.., .., ..) - matches # params used
      \x20*                             # any number of spaces
      {                                 # parenthesis 
      ///
      
    extension = path.extname(editor.getPath())
    if !extension?
      atom.notifications.addError("Failed to get extension for path: " + editor.getPath(), {dismissable: true})
      return
      
    results = []
    atom.workspace.scan functionDeclarationPattern, paths: ["*" + extension], (result) -> 
      results.push(result)
    .then (res) => 
      if results.length == 0
        atom.notifications.addError("Couldn't find any files matching function: " + functionName, {dismissable: true})
        return
        
      fileReadPromises = []
      functionMatches = []
      for result in results
        fileAction = @findFunctionMatches(result.filePath, functionMatches, functionDeclarationPattern)
        fileReadPromises.push(fileAction)
      
      Promise.all(fileReadPromises).then (res) =>
        @foundAllDefinitionMatches(functionMatches)
  
  findFunctionMatches: (currentFilePath, functionMatches, functionDeclarationPattern) ->
    file = new File(currentFilePath)
    file.read().then (fileText) -> 
      lines = fileText.split("\n")
      
      rowIndex = 1
      for line in lines
        match = line.match(functionDeclarationPattern)
        if match?
          functionMatches.push({filePath: currentFilePath, rowIndex: rowIndex})
        rowIndex++
  
  foundAllDefinitionMatches: (functionMatches) ->
    if functionMatches.length == 1
      @goToDefinitionMatch(functionMatches[0])
    else 
      viewObjects = []
      for functionMatch in functionMatches
        functionMatch.simpleText = path.basename(functionMatch.filePath) + ":" + functionMatch.rowIndex
        functionMatch.detailText = functionMatch.filePath
        viewObjects.push(functionMatch)
      
      @setItems(viewObjects)
      @show()
  
  goToDefinitionMatch: (definitionMatch) ->
    @openPathToRow(definitionMatch.filePath, definitionMatch.rowIndex)
    
  openPathToRow: (filePath, rowIndex) ->
    if filePath
      atom.workspace.open(filePath).done => @moveToRowIndex(rowIndex)
      
  moveToRowIndex: (rowIndex) ->
    return unless rowIndex > 0

    if textEditor = atom.workspace.getActiveTextEditor()
      # buffer is zero indexed, but we display to user starting from 1
      # so subtract 1 when finding position
      position = new Point(rowIndex - 1)
      textEditor.scrollToBufferPosition(position, center: true)
      textEditor.setCursorBufferPosition(position)
      textEditor.moveToFirstCharacterOfLine()
    
  #endregion

  confirmed: (obj) ->
    super()
    @goToDefinitionMatch(obj)

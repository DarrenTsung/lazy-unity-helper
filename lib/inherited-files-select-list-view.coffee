path = require 'path'
{File} = require 'atom'
LazyUnityHelperView = require './lazy-unity-helper-view.coffee'

module.exports =
class InheritedFilesSelectListView extends LazyUnityHelperView
  currentBaseClassName: null
    
  #region mark - LOGIC
  confirmed: (obj) ->
    super()
    @insertOverridableFunctionsFromFilePath(obj.detailText)
  
  foundFilePaths: (filePaths) ->
    if filePaths.length == 1
      @insertOverridableFunctionsFromFilePath(filePaths[0])
    else
      items = []
      for filePath in filePaths
        items.push({simpleText: path.basename(filePath), detailText: filePath})
        
      @setItems(items)
      @show()
      
  insertInheritedFunctions: ->
    editor = atom.workspace.getActiveTextEditor()
    allText = editor.getText()
    
    classPattern = /^[\w ]+class (\w+)\W+(\w+).*{.*$/m
    [_, className, baseClassName] = allText.match(classPattern)
    
    unless baseClassName?
      atom.notifications.addError("Failed to get base class name!", {dismissable: true})
      return
    
    @currentBaseClassName = baseClassName
    
    extension = path.extname(editor.getPath())
    if !extension?
      atom.notifications.addError("Failed to get extension for path: " + editor.getPath(), {dismissable: true})
      return
    
    baseClassPattern = new RegExp("class " + baseClassName + " ", "g")
    results = []
    atom.workspace.scan(baseClassPattern, paths: ["*" + extension], (result) -> 
      results.push(result.filePath)
    ).then (res) => (
      if results.length == 0
        atom.notifications.addError("Couldn't find any files for: " + baseClassPattern + " with extension: " + extension, {dismissable: true})
        return
        
      @foundFilePaths(results)
    )
      
  insertOverridableFunctionsFromFilePath: (filePath) ->
    baseClassFile = new File(filePath)
    baseClassFile.read().then (baseClassText) => (
      overridableFunctions = @findAllOverridableFunctions(baseClassText)
      if overridableFunctions?
        editor = atom.workspace.getActiveTextEditor()
        
        editor.moveDown(1)
        editor.moveToBeginningOfLine()
        editor.insertNewline()
        editor.moveUp(1)
        
        pasteText = ""
        firstMatchPassed = false
        for functionText in overridableFunctions
          newFunctionText = functionText.replace("virtual", "override")
          
          if firstMatchPassed
            pasteText += "\n"
          pasteText += "\n" + newFunctionText + "\n\n}"
          
          firstMatchPassed = true
          
        editor.insertText(pasteText, autoIndent: true)
    )

  findAllOverridableFunctions: (fileText) -> 
    overridableFunctionsPattern = /^\ *(\w+ (virtual|override).*{).*$/gm
    allMatches = []
    fileText.replace overridableFunctionsPattern, (m, g1) ->
      allMatches.push(g1)
    
    if allMatches.length == 0
      atom.notifications.addWarning("Couldn't find any matches inside file: " + filePath, {dismissable: true})
      return
    
    return allMatches
    
  #endregion
  
  show: ->
    super()
    if @currentBaseClassName?
      @filterEditorView.setText(@currentBaseClassName)

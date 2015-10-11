{File} = require 'atom'
{SelectListView} = require 'atom-space-pen-views'

module.exports =
class InheritedFilesSelectListView extends SelectListView
  currentBaseClassName: null
  
  initialize: ->
    super
    @on 'focusout', => @cancel()

  viewForItem: ({filePath: path}) ->
    element = document.createElement('li')
    fileNameLength = path.match(/\/[^\/]*$/)?[0].length
    maxLength = 40 + fileNameLength
    element.innerText = if path.length > maxLength + 2 then ".." + path[path.length-maxLength..] else path
    element

  getFilterKey: -> 'filePath'

  confirmed: ({filePath: path}) ->
    @insertOverridableFunctionsFromFilePath(path)
    @cancel()
    
  destroy: ->
    @currentBaseClassName = null
    @cancel()
    @panel?.destroy()
    
  show: ->
    @storeFocusedElement()
    @panel ?= atom.workspace.addModalPanel(item: this)
    @panel.show()
    if @currentBaseClassName?
      @filterEditorView.setText(@currentBaseClassName)
    @focusFilterEditor()
    
  hide: ->
    @panel?.hide()
      
  cancelled: ->
    @hide()
    
  foundFilePaths: (filePaths) ->
    if filePaths.length == 1
      @insertOverridableFunctionsFromFilePath(filePaths[0].filePath)
    else
      @setItems(filePaths)
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
    
    title = editor.getTitle()
    [_, extension] = title.match(/^.*?\.(\w+)$/)
    if !extension?
      atom.notifications.addError("Failed to get extension for title: " + title, {dismissable: true})
      return
    
    baseClassPattern = new RegExp("class " + baseClassName + " ", "g")
    results = []
    atom.workspace.scan(baseClassPattern, paths: ["*\." + extension], (result) -> 
      results.push({filePath: result.filePath})
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

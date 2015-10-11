path = require 'path'
{File} = require 'atom'
{$$, SelectListView} = require 'atom-space-pen-views'
{match} = require 'fuzzaldrin'

module.exports =
class LazyUnityHelperView extends SelectListView
  #region mark - INHERITED
  
  initialize: ->
    super
    @on 'focusout', => @cancel()

  viewForItem: (obj) ->
    simpleText = obj.simpleText
    detailText = obj.detailText
    
    # Style matched characters in search results
    filterQuery = @getFilterQuery()
    matches = match(detailText, filterQuery)

    $$ ->
      highlighter = (path, matches) =>
        lastIndex = 0
        matchedChars = [] # Build up a set of matched chars to be more semantic

        for matchIndex in matches
          continue if matchIndex < 0 # If marking up the basename, omit path matches
          unmatched = path.substring(lastIndex, matchIndex)
          if unmatched
            @span matchedChars.join(''), class: 'character-match' if matchedChars.length
            matchedChars = []
            @text unmatched
          matchedChars.push(path[matchIndex])
          lastIndex = matchIndex + 1

        @span matchedChars.join(''), class: 'character-match' if matchedChars.length

        # Remaining characters are plain text
        @text path.substring(lastIndex)

      @li class: 'two-lines', =>
        detailMaxLength = 35 + simpleText.length 
        detailTextString = if detailText.length > detailMaxLength + 2 then ".." + detailText[detailText.length-detailMaxLength..] else detailText
        
        @div class: "primary-line file", 'data-name': simpleText, 'data-path': detailText, -> highlighter(simpleText, matches)
        @div class: 'secondary-line path no-icon', -> highlighter(detailTextString, matches)

  getFilterKey: -> 'detailText'

  confirmed: (obj) ->
    @cancel()
    
  destroy: ->
    @cancel()
    @panel?.destroy()
    
  show: ->
    @storeFocusedElement()
    @panel ?= atom.workspace.addModalPanel(item: this)
    @panel.show()
    @focusFilterEditor()
    
  hide: ->
    @panel?.hide()
      
  cancelled: ->
    @hide()
    
  #endregion

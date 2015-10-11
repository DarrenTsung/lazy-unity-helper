# lazy-unity-helper package

A non-efficient package for functions that help unity development

      'lazy-unity-helper:insert-inherited-functions': => 
        # Function Overview: (this works / is tested for c# only)
        # 1. does a regex search for the base class name
        # 2. searches project for files with 'public BaseClassName '
        # 3. if files.length == 1, use that file otherwise present user list of files to choose
        # 4. regex search for all virtual / override functions
        # 5. insert them where the user cursor is
        
      'lazy-unity-helper:jump-to-definition': => 
        # Function Overview: (this works / is tested for c# only)
        # 1. verifies that the current word under cursor looks like a function
        # 2. makes a regex pattern that matches methods with same # of params and name
        # 3. find all matches in all files found and the row index
        # 4. if only one match, use that match otherwise present user with list of matches
        # 5. go to that filePath / that row index

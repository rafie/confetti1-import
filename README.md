confetti1-import
================

Default configuration
---------------------
view_path: 'm:/vtrofymyuk_view1'  
git_path: 'm:/vtrofymyuk_view1\git'
exclude_size: 1000000
ignore_list:
  - ['**', 'lost+found', '**', '*']
  - ['**', 'lost+found', '*']
  - ['**', 'Release', 'bin', '**', '*']
  - ['**', 'Release', 'bin', '*'] , where:

view_path - path to dynamic view
git_path - path to GIT dot folder (.git). NOTE: I was not permitted to write inside view, so this should be overridden.
exclude_size - maximum file size to import (in bytes)
ignore_list - lists of ignorable files as array:

'**/folder/file' == ['**', 'folder', 'file'] - I had problems with different path separators in Windows, so such format will prevent any collisions.

Available environment variables
-------------------------------
**GIT_PATH** - overrides git_path

**VIEW_PATH** - overrides view_path

**EXCLUDE_SIZE** - overrides exclude_size

**CLONE_PATH** - path to clone imported repository for testing. NOTE: it should not be the same as GIT_PATH or application working directory.

How to run
----------
After environment variables configuration run:
```ruby
ruby confetti-import.rb init
```
inside application working directory (running outside I have not tested)

Run times
---------
To import 3 small VOBs it takes 2 coffees
To import full version it will take 2 coffees with cake.

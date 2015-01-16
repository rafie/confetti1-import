confetti1-import
================

Default configuration
---------------------
`view_path: m:/vtrofymyuk_view1`  
`git_path: m:/vtrofymyuk_view1\git`
exclude_size: 1000000
ignore_list:
```ruby
  - ['**', 'lost+found', '**', '*']
  - ['**', 'lost+found', '*']
  - ['**', 'Release', 'bin', '**', '*']
  - ['**', 'Release', 'bin', '*'] 
```
  , where:

`view_path` - path to dynamic view
`git_path` - path to GIT dot folder (.git). NOTE: I was not permitted to write inside view, so this should be overridden.
`exclude_size` - maximum file size to import (in bytes)
`ignore_list` - lists of ignorable files as array:

`**/folder/file == ['**', 'folder', 'file']` - I had problems with different path separators in Windows, so such format will prevent any collisions.

Available environment variables
-------------------------------
`GIT_PATH` - overrides git_path

`VIEW_PATH` - overrides view_path

`EXCLUDE_SIZE` - overrides exclude_size

`CLONE_PATH` - path to clone imported repository for testing. NOTE: it should not be the same as GIT_PATH or application working directory.

`HANDLE_BIG` - import to GIT files bigger then EXCLUDE_SIZE

How to
----------

Initialize a Git respository
```
import.rb --init
```

Build versions forrest
```
import.rb --build-versions
```

 
Import a specific version to master branch:
```
import.rb --version mcu-7.6.1/7.6.1.4.0
```
 
 
Import a series of versions to master branch
```
import.rb --version mcu-7.6.1/7.6.1.1.0
import.rb --version mcu-7.6.1/7.6.1.2.0
import.rb --version mcu-7.6.1/7.6.1.3.0
```
 
 
Import a series of versions to `mcu-7.6.1_int` branch, placing the given tags:
```
import.rb --branch mcu-7.6.1_int --version 7.6.1.1.0 --tag mcu_7.6.1.1.0
import.rb --branch mcu-7.6.1_int --version 7.6.1.2.0 --tag mcu_7.6.1.2.0
import.rb --branch mcu-7.6.1_int --version 7.6.1.3.0 --tag mcu_7.6.1.3.0
```

 
Imports versions under versions/mcu-7.6.1 on branch defined in `versions/mcu-7.6.1/int_branch.txt`:
```
import.rb --product mcu-7.6.1
```

Same as before, just create the branch looking at origin version `mcu_7.5.1.10.8`:
```
import.rb --product mcu-7.6.1 --from-tag mcu_7.5.1.10.8
```




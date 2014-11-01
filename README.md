confetti1-import
================

ClearCase-to-git import scripts

Building:

git clone https://github.com/rafie/confetti1-import
cd confetti1-import
gem build confetti1-import.gemspec
gem install confetti1-import-0.0.0.gem

Usage:

confetti < folder_to_added_to_gir > < git repository >
(confetti /Users/linuxoid/workspace/dev/confetti_test https://github.com/deut/test_repo.git)

TODO:
1) Not working in Windows, currently fixing it.
2) Config for ignored files.
3) Logs.
4) Tests.


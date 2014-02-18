#!/bin/bash
# Pre-commit hook for running basic tests at git commit
# To install, create a soft link from this file into .git/hooks/pre-commit, ie
#   ln -s pre-commit.sh .git/hooks/pre-commit

echo
echo "============================================"
echo "Running pre-commit tests from test/runall.rb"
echo "============================================"
echo

cd src
ruby -I. test/runall.rb

rc=$?

if [[ $rc != 0 ]]; then
  echo
  echo
  echo "** Some pre-commit tests failed. Please fix before trying to commit again. **"
  echo 
  exit 1
fi


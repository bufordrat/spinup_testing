#!/bin/sh

# verbosity for debuggage
set -e
set -x

# name of the sandboxed switch we'll be creating
SWITCH_NAME=$PWD/$1-branch

function there_are_updates() {
    if git -C $1-branch remote update > /dev/null 2> /dev/null && git -C $1-branch diff --quiet origin/$1
    then false
    else true
    fi
}

PROJECT_NAME=wowza

if there_are_updates $1 || $FORCE_TESTS
then git -C $1-branch stash
     git -C $1-branch fetch --all
     git -C $1-branch pull origin $1
     cd $1-branch 
     opam switch remove $SWITCH_NAME --yes || true
     opam switch set ocaml-basics
     eval $(opam env)
     opam exec -- dune clean
     rm -rf _opam || true
     opam switch create . --deps-only --repos dldc=https://dldc.lib.uchicago.edu/opam,default --yes
     eval $(opam env)
     opam exec -- dune build
     opam exec -- dune exec spinup $PROJECT_NAME
     cd $PROJECT_NAME
     opam exec -- dune build
     opam exec -- dune exec $PROJECT_NAME
     opam exec -- dune test
     cd ..
     rm -rf $PROJECT_NAME
else echo "build-run-delete: nothing to do."
fi

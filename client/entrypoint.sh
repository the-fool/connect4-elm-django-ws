#! /bin/bash
cmd="$@"
npm i
elm-package install --yes

exec $cmd

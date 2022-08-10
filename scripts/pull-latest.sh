#! /usr/bin/env bash

IFS=$'\n'
for DIR in $(git submodule foreach -q sh -c pwd); do
    cd "$DIR" && git fetch --all --tags --force &
done
wait

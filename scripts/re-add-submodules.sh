#!/bin/sh

# to delete: https://gist.github.com/myusuf3/7f645819ded92bda6677

set -e

git config -f .gitmodules --get-regexp '^submodule\..*\.path$' |
    while read path_key path; do
        url_key=$(echo "$path_key" | sed 's/\.path/.url/')
        url=$(git config -f .gitmodules --get "$url_key")
        git submodule add "$url" "$path"
    done

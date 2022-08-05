#! /usr/bin/env bash

set -eu

echo
echo "Python version is $PYTHON_VERSION"
echo "Node version is $NODE_VERSION"
echo

npm i -g prettier

./scripts/init-submodules.sh 

pip3 install poetry 

poetry config virtualenvs.in-project true 

poetry install --no-dev

poetry run bb-docs-compiler -l 1
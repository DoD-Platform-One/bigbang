#! /usr/bin/env bash

set -eu

npm install prettier --location=global

pip3 install poetry

poetry config virtualenvs.in-project true

poetry install --no-dev

poetry run bb-docs-compiler

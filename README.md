# bb-docs-compiler

> v2.0 Declarative Edition

## Requirements

- Python v3.9+
- `prettier` installed (`npm i -g prettier`)
- An internet connection

## Install

```bash
git clone <this repo>

cd <this repo>

git submodule update --init --recursive

git submodule update --remote

pip3 install poetry

poetry config virtualenvs.in-project true

poetry install --no-dev
```

## Usage

```bash
# get help
poetry run bb-docs-compiler -h

# compile docs for latest Big Bang tag, and run dev server
poetry run bb-docs-compiler compile --last-x-tags 1 --dev

# compile docs for last 3 Big Bang tags
poetry run bb-docs-compiler compile -l 3

# build assets located in `site`
```


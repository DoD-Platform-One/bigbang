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

./scripts/update-submodules.sh

git submodule update --remote

./scripts/fetch-tags.sh

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
# there is no current way to run as dev
poetry run bb-docs-compiler compile -l 3

# build assets located in `site`, use python's built in webserver to view them
python3 -m http.server --directory site
```


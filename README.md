# bb-docs-compiler

[![Playwright e2e Tests](https://github.com/Noxsios/bb-docs-compiler/actions/workflows/test.yaml/badge.svg)](https://github.com/Noxsios/bb-docs-compiler/actions/workflows/test.yaml)

> v2.0 Declarative Edition

## Requirements

- Python v3.9+
- `prettier` installed (`npm install prettier --location=global`)
- An internet connection

## Install

```bash
git clone <this repo>

cd <this repo>

./scripts/init-submodules.sh

pip3 install poetry

poetry config virtualenvs.in-project true

poetry install --no-dev
```

![Demo GIF](base/static/img/demo.gif)

## Usage

```bash
# get help
poetry run bb-docs-compiler -h
Usage: bb-docs-compiler [OPTIONS]

Options:
  -t, --tag TEXT     Build docs from Big Bang tag <tag>
  -b, --branch TEXT  Build docs from Big Bang branch <branch>
  --pre-release      Build for `release-1.X.0` (only for release engineering)
  -c, --clean        Destroy + reset resources after build
  -o, --outdir TEXT  Output build folder, default (site)
  --no-build         Compile the `docs` folder but do not render w/ mkdocs
  -d, --dev          Run `mkdocs serve` after build
  -h, --help         Show this message and exit.

  Built and maintained by @razzle
```

### Usage Examples

```bash
# compile docs for latest Big Bang tag, and run dev server
poetry run bb-docs-compiler --dev

# compile docs for <branch> of Big Bang
poetry run bb-docs-compiler --branch <branch>

# compile docs for <tag> of Big Bang
poetry run bb-docs-compiler --tag <tag>

# build assets located in `site`, use python's built in webserver to view them
python3 -m http.server --directory site
```

## Usage in Big Bang's Release Engineering

1. Follow [install](#install) instructions
2. Make sure that the `release-1.X.0` branch is created w/ `r2d2`
3. Compile the docs for the current pre-release branch

    ```bash
    poetry run bb-docs-compiler --pre-release --no-build
    ```

4. In different terminals, start the dev server and run the `playwright` e2e tests

    ```bash
    poetry run mkdocs serve
    ```

    ```bash
    npm test
    ```

5. Review any failures, refactor tests if need be. Ping `@razzle` for assistance if needed.
6. Once tests are passing, navigate to http://localhost:8000 and explore for a bit.
7. Continue w/ release engineering, rerun steps 3-4 if any cherry-picks affect `docs`.


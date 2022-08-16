# bb-docs-compiler

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

# compile docs for latest Big Bang tag, and run dev server
poetry run bb-docs-compiler --dev

# compile docs for last 3 Big Bang tags
# there is no current way to run as dev
poetry run bb-docs-compiler --last-x-tags 3

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


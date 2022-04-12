# BigBang Package README Template

## Updating README.md for BigBang package

Each BigBang package should be using this standardized README template in gluon, with more information inside a `docs/` folder with an `overview.md` file. Below are three options to generate this README: manually running each command, tying all commands to an alias, or running as a pre-commit hook.

### Manual Method

To update/generate this README.md for a package using the template perform the following:

```bash
curl -O https://repo1.dso.mil/platform-one/big-bang/apps/library-charts/gluon/-/raw/master/docs/README.md.gotmpl
curl -O https://repo1.dso.mil/platform-one/big-bang/apps/library-charts/gluon/-/raw/master/docs/.helmdocsignore
docker run --rm -v "$(pwd):/helm-docs" -u $(id -u) jnorwood/helm-docs:v1.5.0 -s file -t /helm-docs/README.md.gotmpl --dry-run > README.md
rm .helmdocsignore README.md.gotmpl
```

This will output into (or populate) the existing README.md that is in the root of the package repo. Push up this new README.md up with your package changes.

### Alias Method

Since this is a lot to remember/copy each time you update a package it can be helpful to alias the commands:

```bash
alias readme='curl -O https://repo1.dso.mil/platform-one/big-bang/apps/library-charts/gluon/-/raw/master/docs/README.md.gotmpl && curl -O https://repo1.dso.mil/platform-one/big-bang/apps/library-charts/gluon/-/raw/master/docs/.helmdocsignore && docker run --rm -v "`pwd`:/helm-docs" -u $(id -u) jnorwood/helm-docs:v1.5.0 -s file -t /helm-docs/README.md.gotmpl --dry-run > README.md && rm README.md.gotmpl .helmdocsignore'
```

### Pre-Commit Hook Method

If you want to go a step further you can run everything as a pre-commit hook so that you don't need to run the alias even. To set this up, copy the below script to individual repos at the path `.git/hooks/pre-commit`.

```bash
#!/bin/bash
#
#  .git/hooks/pre-commit
#

files=$(git diff --cached --name-only --diff-filter=ACDMR | tr '\n' ',')
if [[ ! ("$files" =~ (^|,)(README\.md|chart\/(Chart|requirements|values)\.yaml)($|,)) ]]; then
  exit 0
fi

curl -sS -O https://repo1.dso.mil/platform-one/big-bang/apps/library-charts/gluon/-/raw/master/docs/README.md.gotmpl
curl -sS -O https://repo1.dso.mil/platform-one/big-bang/apps/library-charts/gluon/-/raw/master/docs/.helmdocsignore

# Update to your helm-docs binary path
/usr/local/bin/helm-docs -s file -t `pwd`/README.md.gotmpl --dry-run > README.md
# Uncomment to use docker
# docker run --rm -v "`pwd`:/helm-docs" -u $(id -u) jnorwood/helm-docs:v1.5.0 -s file -t /helm-docs/README.md.gotmpl --dry-run > README.md

rm README.md.gotmpl .helmdocsignore
git add README.md
```

NOTE: In testing the binary (which can be pulled from [here](https://github.com/norwoodj/helm-docs/releases) or built from source) tends to be quicker than running with docker, although the docker run command is included in the above script as an option (simply uncomment it and comment out the `/usr/local/bin` call).

## Notes
[Helm-docs](https://github.com/norwoodj/helm-docs) uses a `.helmdocsignore` file to ignore dependencies or other linked charts, otherwise by default all found Chart.yaml's will be outputted into the generated README.

[helmdocsignore information](https://github.com/norwoodj/helm-docs#ignoring-chart-directories)

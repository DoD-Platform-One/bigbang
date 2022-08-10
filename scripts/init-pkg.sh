#! /usr/bin/env bash

set -eu

pkg_name=$1

mkdir base/packages/"$pkg_name"
touch base/packages/"$pkg_name"/config.yaml

cat <<EOF >base/packages/"$pkg_name"/config.yaml

source: submodules/$pkg_name

ignore_patterns:
  - .gitattributes
  - .gitignore
  - CODEOWNERS
  - oscal-component.yaml
  - renovate.json
  - "*.tgz"
  - "*.zip"
  - Dockerfile
  - tests
  - LICENSE
  - .pre-commit-config.yaml


nav:
  - 📦 Home: README.md
  - 🪙 Values: values.md
  - 👥 Contributing: CONTRIBUTING.md
  - 📜 Changelog: CHANGELOG.md
  - 📖 More Info: docs
EOF

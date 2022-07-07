#! /usr/bin/env bash

set -eu pipefail

echo "👉 Removing any [[_TOC_]] headers"

find . -iname '*.md' -exec sed -i -e '/^\[\[_TOC_\]\]$/d' {} \;
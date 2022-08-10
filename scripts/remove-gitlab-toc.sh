#! /usr/bin/env bash

set -eu

echo "👉 Removing any [[_TOC_]] headers"

find ./docs -iname '*.md' -exec sed -i -e '/^\[\[_TOC_\]\]$/d' {} \;

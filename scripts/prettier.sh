#! /usr/bin/env bash

set -eu

prettier --write --prose-wrap=preserve --loglevel=warn docs 

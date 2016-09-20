#!/bin/sh -e
# Show release tag for development build. "20160919093435gitb064bb7"
timestamp=$(date --date="$(git show -s --format=%cd --date=iso HEAD)" +%Y%m%d%H%M%S)
echo "${timestamp}git$(git rev-parse --short HEAD)"

#!/bin/bash
set -e

for v in */; do
	dir="${v%/}"
  v="${v%/}"
  sed "s/%VERSION%/$v/g" Dockerfile.template > "$dir/Dockerfile"
done
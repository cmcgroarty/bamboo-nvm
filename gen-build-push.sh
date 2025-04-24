#!/bin/bash
set -e

for v in */; do
	v="${v%/}"
	sed "s/%VERSION%/$v/g" Dockerfile.template >"$v/Dockerfile"
	./build.sh "$v"
done

docker image push --all-tags cmcg/bamboo-nvm
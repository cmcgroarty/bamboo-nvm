#!/bin/bash
set -e
tag=${1}
docker build -t cmcg/bamboo-nvm:"$tag" -f ./"$tag"/Dockerfile .
#!/bin/bash
set -e
docker build -t cmcg/bamboo-nvm:latest .
docker push cmcg/bamboo-nvm:latest

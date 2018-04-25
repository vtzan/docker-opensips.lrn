#!/bin/bash
command -v docker >/dev/null 2>&1 || { echo "Docker is required, but missing"; exit 1; }
docker build --no-cache --tag="opensips/opensips-lrn:2.2" .


#!/bin/bash

dockerid=`docker ps|grep opensips-lrn|awk -F " " '{print $1}'`

docker exec -it $dockerid bash

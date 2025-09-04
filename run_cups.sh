#!/bin/bash

CONTAINER_NAME=cups-qnap-hplip-plugin
ETC_VOL=${CONTAINER_NAME}-etc

docker volume create $ETC_VOL

docker build -t $CONTAINER_NAME ./

docker rm -f $CONTAINER_NAME 2>/dev/null || true

docker run -d \
  --name $CONTAINER_NAME \
  --network host \
  --restart unless-stopped \
  --privileged \
  --device-cgroup-rule='c 166:* rwm' \
  -v $ETC_VOL:/etc/cups \
  $CONTAINER_NAME

docker exec -it $CONTAINER_NAME bash /usr/local/bin/install-hp-plugin.sh
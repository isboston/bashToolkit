#!/bin/bash

IMAGE="hello-world"

docker rmi $IMAGE --force || true

for i in {1..150}
do
    echo "Pull attempt #$i"
    docker pull $IMAGE || true
    docker rmi $IMAGE --force || true
    sleep 1
done

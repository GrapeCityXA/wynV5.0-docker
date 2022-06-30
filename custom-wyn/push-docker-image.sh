#!/bin/bash

# $1 - tag name
if [ "" == "$1" ]; then
  echo "Error: empty tag name."
  exit 1
fi

echo "build docker image"
sudo docker rmi {docker-image-name} > /dev/null 2>/dev/null
sudo docker build -t {docker-image-name} -f dockerfile .

sudo docker login {docker-repository} -u {username} -p {password}

echo "tag docker image"
sudo docker tag custom-wyn {docker-repository}/{docker-image-name}:$1
sudo docker tag custom-wyn {docker-repository}/{docker-image-name}:latest

echo "push docker image"
sudo docker push {docker-repository}/{docker-image-name}:$1
sudo docker push {docker-repository}/{docker-image-name}:latest

echo "cleanup docker image"
sudo docker rmi {docker-repository}/{docker-image-name}:$1
sudo docker rmi {docker-repository}/{docker-image-name}:latest

echo "finished"
exit 0

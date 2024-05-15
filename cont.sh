#!/bin/bash

CONT_OS="ubuntu:latest"
BASE_IMAGE_NAME="cont"
ALIAS="cont"
SCRIPT_URL="https://raw.githubusercontent.com/sswastik02/cont/main/cont.sh"

set -e

if ! [ -x "$(command -v docker)" ]; then
  echo -e "Install Docker (https://get.docker.com)"
  exit 1
fi

path_to_docker_image_name() {
  local path=$PWD
  local docker_name="${path//\//-}"
  docker_name="${docker_name##-}"

  echo -e $docker_name
}

create_base_docker_image() {
  base_docker_image_id=$(docker images -q $BASE_IMAGE_NAME) # Get image id of base image
  if [ -z $base_docker_image_id ]; then 
    echo -e "Base image not found. Creating \"$BASE_IMAGE_NAME\" base image..."
    docker pull $CONT_OS # Pull base image dependency
    docker run -it --name cont_base $CONT_OS /bin/bash -c "apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential software-properties-common" # update and create the base image
    docker commit cont_base $BASE_IMAGE_NAME 
  else
    echo -e "Base image \"$BASE_IMAGE_NAME\" already present"
  fi

}

suggest_shortcut() {
  echo -e "You might want to add these lines to bashrc or zshrc and use \"cont\" instead:"
  echo -e "\nalias cont=\"CONT_DISABLE_SUGGEST=TRUE bash <(wget -qO- $SCRIPT_URL)\"\n"
  echo -e "To disable this suggestion set the environment variable CONT_DISABLE_SUGGEST"
}

run_cont() {
  create_base_docker_image # Create the base docker image
  local img=$(path_to_docker_image_name) # Get image name from current path 
  img_id=$(docker images -q $img) # Get img id to check if image exists
  if [ -z $img_id ]; then
    echo -e "$img not present. Creating..."
    docker run -it --name $img-cont -v $PWD:/mnt $BASE_IMAGE_NAME /bin/bash # Create from base image as image does not exist
  else
    docker run -it --name $img-cont -v $PWD:/mnt $img /bin/bash # Create from previous image
  fi
  docker commit $img-cont $img # commit current state into image
  docker rm $img-cont # remove exited container
  if [ -z "$CONT_DISABLE_SUGGEST" ]; then
    suggest_shortcut
  fi

}


run_cont #Entrypoint


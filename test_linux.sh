# !/bin/bash

set -e

if [[ `uname` == "Darwin" ]]; then
  if [[ -z `which docker-machine 2>/dev/null` || -z `which virtualbox 2>/dev/null` ]] ; then
    echo "Install docker-machine and virtualbox ahead."
    exit -1
  fi

  DOCKER_HOST_NAME=com.ryo.alembic.test
  WORKING_DIR=$(pwd)

  echo "Starting to running tests on Linux by Docker..."
  docker-machine create --driver virtualbox $DOCKER_HOST_NAME || true
  docker run -v $WORKING_DIR:$WORKING_DIR -w $WORKING_DIR -it --privileged swift:4.1 bash -c "$0" || true
  docker-machine stop $DOCKER_HOST_NAME || true
  docker-machine rm -f $DOCKER_HOST_NAME || true
  echo "Tests finish!"

elif [[ `uname` == "Linux" ]]; then
  swift build
  swift test

else
  echo "Unknown OS (`uname`)"
  exit -1

fi
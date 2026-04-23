#!/bin/bash

set -e

# -------------------------
# CONFIG
# -------------------------
env=dev
home_dir=/home/$USER

db_type=mysql
db_version=8.4

db_image_name=${db_type}:${db_version}
db_docker_image=docker.io/library/${db_image_name}

db_data_dir=${home_dir}/${db_type}-data
container_name=${db_type}-${env}

# -------------------------
# FUNCTIONS
# -------------------------

start_db() {
  echo "Creating Database Directory: ${db_data_dir}"
  sudo mkdir -p ${db_data_dir}
  sudo chown -R 999:999 ${db_data_dir}

  echo "Pulling Docker Image: ${db_docker_image}"
  sudo ctr images pull ${db_docker_image}

  echo "Killing existing container (if any)"
  sudo ctr tasks kill ${container_name} || true
  sudo ctr containers delete ${container_name} || true

  echo "Starting Database Container (${db_type})"

  sudo ctr run -d \
    --net-host \
    --env MYSQL_DATABASE=usnf \
    --env MYSQL_USER=mcilek \
    --env MYSQL_PASSWORD=password \
    --env MYSQL_ROOT_PASSWORD=password \
    --mount type=tmpfs,dst=/var/run/${db_type}d \
    --mount type=bind,src=${db_data_dir},dst=/var/lib/${db_type},options=rbind:rw \
    ${db_docker_image} \
    ${container_name}

  echo "Database started on localhost:3306"

  sudo ctr tasks ls
  sudo ctr containers ls

  sudo ctr tasks logs ${container_name} > db.log 2>&1 &
}

stop_db() {
  echo "Stopping Database Container (${container_name})"

  sudo ctr tasks kill ${container_name} || true
  sudo ctr containers delete ${container_name} || true

  echo "Container stopped."

  sudo ctr tasks ls
  sudo ctr containers ls
}

status_db() {
  sudo ctr tasks ls
  sudo ctr containers ls
}

# -------------------------
# ARG PARSING
# -------------------------

case "$1" in
  start)
    start_db
    ;;
  stop)
    stop_db
    ;;
  status)
    status_db
    ;;
  *)
    echo "Usage: $0 {start|stop|status}"
    exit 1
    ;;
esac
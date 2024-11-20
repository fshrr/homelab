#!/bin/bash

# Ensure one parameter is provided
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <volume-name> <device-path>"
  exit 1
fi

# Parameters
VOLUME_NAME=$1
DIRECTORY=$2

IP_ADDRESS="192.168.2.120"  # Replace with your NFS server IP

# NFS options
NFS_OPTIONS="addr=${IP_ADDRESS},rw,noatime,rsize=8192,wsize=8192,tcp,timeo=14,nfsvers=4"

# Create the Docker volume
docker volume create \
  --driver local \
  --opt type=nfs \
  --opt o=${NFS_OPTIONS} \
  --opt device=:${DIRECTORY} \
  ${VOLUME_NAME}

# Verify the volume was created
if [ $? -eq 0 ]; then
  echo "Docker volume '${VOLUME_NAME}' created successfully."
else
  echo "Failed to create Docker volume '${VOLUME_NAME}'."
  exit 2
fi

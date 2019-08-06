#!/bin/bash
set -e

docker-compose -p RaspiDeb64-rootfs build
docker-compose -p RaspiDeb64-rootfs run builder
docker-compose -p RaspiDeb64-rootfs down

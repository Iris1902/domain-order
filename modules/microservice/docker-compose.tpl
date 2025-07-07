#!/bin/bash
exec > >(tee /dev/tty) 2>&1
set -x
apt update -y
apt install -y docker.io curl
curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

cat <<EOL > /home/ubuntu/docker-compose.yml
version: '3'
services:
  order-create:
    image: ${image_order_create}
    ports:
      - "${port_order_create}:4000"
    environment:
      - MONGO_URL=${mongo_url}
  order-read:
    image: ${image_order_read}
    ports:
      - "${port_order_read}:4001"
    environment:
      - MONGO_URL=${mongo_url}
  order-add:
    image: ${image_order_add}
    ports:
      - "${port_order_add}:4002"
    environment:
      - MONGO_URL=${mongo_url}
  order-delete:
    image: ${image_order_delete}
    ports:
      - "${port_order_delete}:4003"
    environment:
      - MONGO_URL=${mongo_url}
EOL

systemctl start docker
systemctl enable docker
cd /home/ubuntu
docker-compose up -d

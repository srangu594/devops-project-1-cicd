#!/bin/bash
set -euo pipefail
IMAGE=$1
TAG=$2
NAME=$3
PORT=$4

echo "==> Pulling ${IMAGE}:${TAG}"
docker pull "${IMAGE}:${TAG}"
docker stop "${NAME}" 2>/dev/null || true
docker rm   "${NAME}" 2>/dev/null || true
docker run -d \
    --name "${NAME}" \
    --restart unless-stopped \
    -p "${PORT}:5000" \
    -e APP_VERSION="${TAG}" \
    -e ENVIRONMENT=production \
    "${IMAGE}:${TAG}"
echo "==> Deployed ${NAME}"
docker ps --filter "name=${NAME}" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

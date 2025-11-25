#!/usr/bin/env bash

set -x

GITEA_IMAGE="gitea/gitea:1.13.2"

GITEA_HTTP_METHOD="http"
GITEA_URL="localhost:3000"
GITEA_USERNAME="admin"
GITEA_PASSWORD="password"

curl -X POST "${GITEA_HTTP_METHOD}://${GITEA_USERNAME}:${GITEA_PASSWORD}@${GITEA_URL}/api/v1/user/repos" -H "accept: application/json" -H "content-type: application/json" -d \
  "{\"name\":\"test-repo\", \"description\": \"Sample description\" }"
  
#!/bin/sh
set -exu

echo running "${0}"

if ! command -v openssl &> /dev/null; then
  echo "Installing openssl..."
  apk add openssl
fi

BEDROCK_JWT_PATH=/jwt/jwt.txt
if [ -e "$BEDROCK_JWT_PATH" ]; then
  echo "Already created jwt.txt"
else
  echo "Creating jwt.txt..."
  mkdir -p $(dirname $BEDROCK_JWT_PATH)
  openssl rand -hex 32 > $BEDROCK_JWT_PATH
fi

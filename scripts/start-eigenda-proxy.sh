#!/bin/sh
set -e

if [ -n "$EIGENDA_PROXY_ENDPOINT" ]; then
  echo "Not starting local EigenDA proxy since proxy endpoint ($EIGENDA_PROXY_ENDPOINT) is defined"
  exit
fi

# Archive blobs configuration
if [ -n "$EIGENDA_LOCAL_ARCHIVE_BLOBS" ]; then
  export EXTENDED_EIGENDA_PARAMETERS="${EXTENDED_EIGENDA_PARAMETERS:-} --s3.credential-type=$EIGENDA_LOCAL_S3_CREDENTIAL_TYPE \
  --s3.access-key-id=$EIGENDA_LOCAL_S3_ACCESS_KEY_ID \
  --s3.access-key-secret=$EIGENDA_LOCAL_S3_ACCESS_KEY_SECRET \
  --s3.bucket=$EIGENDA_LOCAL_S3_BUCKET \
  --s3.path=$EIGENDA_LOCAL_S3_PATH \
  --s3.endpoint=$EIGENDA_LOCAL_S3_ENDPOINT \
  --storage.fallback-targets=s3"
fi

exec ./eigenda-proxy --addr=0.0.0.0 \
  --port=4242 \
  --eigenda.disperser-rpc="$EIGENDA_LOCAL_DISPERSER_RPC" \
  --eigenda.eth-rpc="$OP_NODE__RPC_ENDPOINT" \
  --eigenda.signer-private-key-hex="${EIGENDA_LOCAL_SIGNER_PRIVATE_KEY_HEX:-0123456789012345678901234567890123456789012345678901234567890123}" \
  --eigenda.svc-manager-addr="$EIGENDA_LOCAL_SVC_MANAGER_ADDR" \
  --eigenda.status-query-timeout="45m" \
  --eigenda.disable-tls=false \
  --eigenda.confirmation-depth=1 \
  --eigenda.max-blob-length="16MiB" \
  --storage.backends-to-enable="V1,V2" \
  --eigenda.v2.disperser-rpc="$EIGENDA_V2_LOCAL_DISPERSER_RPC" \
  --eigenda.v2.eth-rpc="$OP_NODE__RPC_ENDPOINT" \
  --eigenda.v2.disable-tls=false \
  --eigenda.v2.blob-certified-timeout="2m" \
  --eigenda.v2.blob-status-poll-interval="1s" \
  --eigenda.v2.contract-call-timeout="5s" \
  --eigenda.v2.relay-timeout="5s" \
  --eigenda.v2.blob-version="0" \
  --eigenda.v2.max-blob-length="16MiB" \
  --eigenda.v2.cert-verifier-addr="$EIGENDA_V2_LOCAL_CERT_VERIFIER_ADD" \
  --eigenda.v2.signer-payment-key-hex="${EIGENDA_V2_LOCAL_SIGNER_PAYMENT_KEY_HEX:-0123456789012345678901234567890123456789012345678901234567890123}" \
  --eigenda.v2.service-manager-addr="$EIGENDA_V2_LOCAL_SVC_MANAGER_ADDR" \
  --eigenda.v2.bls-operator-state-retriever-addr="$EIGENDA_V2_LOCAL_BLS_OPERATOR_STATE_RETRIEVER_ADDR" \
  $EXTENDED_EIGENDA_PARAMETERS

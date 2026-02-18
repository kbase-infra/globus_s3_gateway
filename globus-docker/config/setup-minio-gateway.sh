#!/bin/bash

set -euo pipefail

# Check required environment variables
if [ -z "${MINIO_ENDPOINT:-}" ]; then
    echo "ERROR: MINIO_ENDPOINT environment variable is required" >&2
    echo "Example: MINIO_ENDPOINT=https://minio.example.com:9000" >&2
    exit 1
fi

if [ -z "${MINIO_BUCKET:-}" ]; then
    echo "ERROR: MINIO_BUCKET environment variable is required" >&2
    echo "Example: MINIO_BUCKET=globus-data" >&2
    exit 1
fi

if [ -z "${GCS_DOMAIN:-}" ]; then
    echo "ERROR: GCS_DOMAIN environment variable is required" >&2
    echo "Example: GCS_DOMAIN=globus.example.com" >&2
    exit 1
fi

echo "Creating MinIO S3 storage gateway..."
echo "MinIO Endpoint: ${MINIO_ENDPOINT}"
echo "Bucket: ${MINIO_BUCKET}"
echo "Domain: ${GCS_DOMAIN}"

# Create storage gateway
GATEWAY_OUTPUT=$(globus-connect-server storage-gateway create s3 "MinIO Gateway" \
    --s3-endpoint "${MINIO_ENDPOINT}" \
    --s3-user-credential \
    --domain "${GCS_DOMAIN}" \
    --bucket "${MINIO_BUCKET}")

echo "${GATEWAY_OUTPUT}"

# Extract gateway ID from output
GATEWAY_ID=$(echo "${GATEWAY_OUTPUT}" | grep -oP 'Storage Gateway ID:\s+\K[a-f0-9-]+' || echo "")

if [ -z "${GATEWAY_ID}" ]; then
    echo "ERROR: Failed to extract Storage Gateway ID from output" >&2
    exit 1
fi

echo ""
echo "Storage Gateway created with ID: ${GATEWAY_ID}"
echo ""

# Create collection
COLLECTION_DISPLAY_NAME="${COLLECTION_DISPLAY_NAME:-MinIO Collection}"

echo "Creating collection..."
COLLECTION_OUTPUT=$(globus-connect-server collection create \
    --storage-gateway-id "${GATEWAY_ID}" \
    --display-name "${COLLECTION_DISPLAY_NAME}" \
    --collection-base-path /)

echo "${COLLECTION_OUTPUT}"

# Extract collection ID from output
COLLECTION_ID=$(echo "${COLLECTION_OUTPUT}" | grep -oP 'Collection ID:\s+\K[a-f0-9-]+' || echo "")

echo ""
echo "===================================================================="
echo "MinIO Gateway Setup Complete!"
echo "===================================================================="
echo ""
echo "Storage Gateway ID: ${GATEWAY_ID}"
if [ -n "${COLLECTION_ID}" ]; then
    echo "Collection ID: ${COLLECTION_ID}"
fi
echo ""
echo "Users can now register their MinIO credentials for this collection."
echo ""
echo "To register credentials, users should:"
echo "1. Navigate to the collection in Globus Web App"
echo "2. Click on 'Credentials' tab"
echo "3. Add their MinIO access key and secret key"
echo ""
echo "MinIO credentials format:"
echo "  Access Key: <minio-access-key>"
echo "  Secret Key: <minio-secret-key>"
echo ""

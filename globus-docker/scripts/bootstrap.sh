#!/bin/bash

set -euo pipefail

# Check required environment variables
if [ -z "${GCS_ADMIN_IDENTITY:-}" ]; then
    echo "ERROR: GCS_ADMIN_IDENTITY environment variable is required" >&2
    exit 1
fi

if [ -z "${GCS_ORG:-}" ]; then
    echo "ERROR: GCS_ORG environment variable is required" >&2
    exit 1
fi

if [ -z "${GCS_CONTACT_EMAIL:-}" ]; then
    echo "ERROR: GCS_CONTACT_EMAIL environment variable is required" >&2
    exit 1
fi

# Check if deployment key already exists
if [ -f "/gcs-config/deployment-key.json" ]; then
    echo "ERROR: /gcs-config/deployment-key.json already exists. Bootstrap has already been run." >&2
    echo "If you need to re-bootstrap, please delete the deployment key file first." >&2
    exit 1
fi

# Set display name with fallback
GCS_DISPLAY_NAME="${GCS_DISPLAY_NAME:-Globus Connect Server}"

echo "Starting Globus Connect Server endpoint setup..."
echo "Organization: ${GCS_ORG}"
echo "Contact Email: ${GCS_CONTACT_EMAIL}"
echo "Owner: ${GCS_ADMIN_IDENTITY}"
echo "Display Name: ${GCS_DISPLAY_NAME}"

# Run endpoint setup
globus-connect-server endpoint setup \
    --organization "${GCS_ORG}" \
    --contact-email "${GCS_CONTACT_EMAIL}" \
    --owner "${GCS_ADMIN_IDENTITY}" \
    --display-name "${GCS_DISPLAY_NAME}" \
    --deployment-key /gcs-config/deployment-key.json \
    --agree-to-letsencrypt-tos

echo ""
echo "===================================================================="
echo "Bootstrap complete!"
echo "===================================================================="
echo ""
echo "Deployment key has been saved to: /gcs-config/deployment-key.json"
echo ""
echo "IMPORTANT: Back up the deployment key securely!"
echo "You will need it to manage this endpoint in the future."
echo ""

# Extract and display endpoint ID
if [ -f "/gcs-config/deployment-key.json" ]; then
    if command -v jq >/dev/null 2>&1; then
        ENDPOINT_ID=$(jq -r '.endpoint_id // "unknown"' /gcs-config/deployment-key.json 2>/dev/null || echo "unknown")
    else
        ENDPOINT_ID=$(grep -o '"endpoint_id":"[^"]*"' /gcs-config/deployment-key.json | cut -d'"' -f4 || echo "unknown")
    fi
    echo "Endpoint ID: ${ENDPOINT_ID}"
    echo ""
fi

echo "You can now start the runtime service with:"
echo "  docker-compose up -d globus"
echo ""

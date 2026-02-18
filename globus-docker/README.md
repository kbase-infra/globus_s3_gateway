# Globus Connect Server Docker Deployment

This directory contains a complete Docker-based deployment of Globus Connect Server 5.4 with MinIO S3 backend support, targeting Ubuntu 22.04.

## Overview

This deployment provides:
- Dockerized Globus Connect Server 5.4
- MinIO S3 storage gateway integration
- Automated GitHub Actions CI/CD pipeline
- Host networking for optimal performance
- Persistent configuration and state management

## Prerequisites

- Docker Engine 20.10 or later
- Docker Compose v2.0 or later
- A valid Globus account and administrator identity
- Domain name with proper DNS configuration
- Ports 443 and 50000-51000 available on the host

## Quick Start

### 1. Initial Setup

Copy the example environment file and configure it:

```bash
cd globus-docker
cp .env.example .env
```

Edit `.env` and set the required values:

```bash
GCS_ADMIN_IDENTITY=myuser@globusid.org
GCS_ORG=My Organization
GCS_CONTACT_EMAIL=admin@example.com
GCS_DISPLAY_NAME=My Globus Endpoint
```

### 2. Bootstrap the Endpoint

Run the bootstrap service to create the endpoint and generate the deployment key:

```bash
docker-compose --profile bootstrap up bootstrap
```

**Important:** The deployment key is saved to the `gcs-config` volume and must be backed up securely!

### 3. Start the Runtime Service

After successful bootstrap, start the main Globus Connect Server service:

```bash
docker-compose up -d globus
```

### 4. Check Service Health

Monitor the service status:

```bash
docker-compose ps
docker-compose logs -f globus
```

The healthcheck will verify the service is responding on `https://localhost/api/version`.

## MinIO Gateway Setup

After the endpoint is running, configure the MinIO S3 storage gateway:

```bash
# Set MinIO configuration
export MINIO_ENDPOINT=https://minio.example.com:9000
export MINIO_BUCKET=globus-data
export GCS_DOMAIN=globus.example.com

# Run the gateway setup script
docker-compose exec globus /bin/bash /config/setup-minio-gateway.sh
```

This will:
1. Create an S3 storage gateway pointing to MinIO
2. Create a collection with user credential authentication
3. Display instructions for users to register their MinIO credentials

## Architecture

### Services

**bootstrap** (profile: bootstrap)
- One-time setup service
- Creates the Globus endpoint
- Generates and stores the deployment key
- Must be run before the runtime service

**globus** (runtime)
- Main Globus Connect Server service
- Runs GCS manager assistant, Apache, and GridFTP server
- Monitors processes and exits if any fail
- Uses host networking for optimal performance

### Volumes

- `gcs-config`: Stores deployment key and configuration (read-only on runtime)
- `gcs-state`: Persistent state and data for Globus Connect Server
- `gcs-logs`: Log files from all GCS components

### Networking

This deployment uses `network_mode: host` for both services to:
- Avoid NAT complexities with GridFTP
- Ensure optimal performance
- Simplify port management

## Environment Variables

### Required

- `GCS_ADMIN_IDENTITY`: Globus identity of the endpoint administrator
- `GCS_ORG`: Organization name
- `GCS_CONTACT_EMAIL`: Contact email for the endpoint

### Optional

- `GCS_DISPLAY_NAME`: Display name for the endpoint (default: "Globus Connect Server")
- `GCS_LOG_LEVEL`: Logging level (default: INFO)
- `GCS_IMAGE`: Override Docker image (default: build from local Dockerfile)

## GitHub Actions Workflow

The repository includes a GitHub Actions workflow (`.github/workflows/build-push.yml`) that:

1. Triggers on:
   - Push to `main` branch
   - Pull requests to `main`
   - Manual workflow dispatch

2. Builds the Docker image using BuildKit
3. Tags with `latest` (on main) and git SHA
4. Pushes to GitHub Container Registry (`ghcr.io`)
5. Only pushes images on pushes to main (not PRs)

### Using Pre-built Images

To use a pre-built image from GHCR:

```bash
export GCS_IMAGE=ghcr.io/kbase-infra/globus_s3_gateway/globus-connect-server:latest
docker-compose up -d globus
```

## File Structure

```
globus-docker/
├── Dockerfile                          # Ubuntu 22.04 with GCS 5.4
├── docker-compose.yml                  # Service definitions
├── .env.example                        # Environment template
├── .gitignore                          # Excludes sensitive files
├── .github/
│   └── workflows/
│       └── build-push.yml             # CI/CD pipeline
├── scripts/
│   ├── bootstrap.sh                   # Endpoint setup script
│   └── entrypoint.sh                  # Runtime startup script
└── config/
    └── setup-minio-gateway.sh         # MinIO integration script
```

## Maintenance

### Viewing Logs

```bash
# All services
docker-compose logs -f globus

# Specific component logs (inside container)
docker-compose exec globus tail -f /var/log/globus-connect-server/gridftp.log
```

### Backup

**Critical:** Always back up the deployment key!

```bash
# Extract deployment key from volume
docker run --rm -v globus-docker_gcs-config:/gcs-config -v $(pwd):/backup \
  ubuntu:22.04 cp /gcs-config/deployment-key.json /backup/deployment-key.json.backup
```

### Updating

To update to a newer image:

```bash
docker-compose pull globus
docker-compose up -d globus
```

### Troubleshooting

**Bootstrap fails with "deployment-key.json already exists"**
- The endpoint has already been bootstrapped
- To re-bootstrap, you must first delete the deployment key volume or file

**Service fails healthcheck**
- Check that port 443 is not in use by another service
- Verify Let's Encrypt certificates were issued successfully
- Review logs: `docker-compose logs globus`

**GridFTP connection issues**
- Ensure ports 50000-51000 are open in firewall
- Verify DNS resolves to the correct host
- Check that host networking is enabled

## Security Notes

- The deployment key is highly sensitive and must be protected
- Never commit `.env` files to version control
- Use strong credentials for MinIO
- Keep the Docker image updated with security patches
- Review and restrict network access to the host

## License

This deployment configuration is provided as-is for use with Globus Connect Server, which is subject to the Globus terms of service.

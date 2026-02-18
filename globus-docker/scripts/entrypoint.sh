#!/bin/bash

set -euo pipefail

# Check if deployment key exists
if [ ! -f "/gcs-config/deployment-key.json" ]; then
    echo "ERROR: /gcs-config/deployment-key.json not found" >&2
    echo "Please run bootstrap first with: docker-compose --profile bootstrap up bootstrap" >&2
    exit 1
fi

SENTINEL_FILE="/var/lib/globus-connect-server/.node-setup-done"

# Run node setup on first start only
if [ ! -f "${SENTINEL_FILE}" ]; then
    echo "First start detected. Running node setup..."
    globus-connect-server node setup --deployment-key /gcs-config/deployment-key.json
    touch "${SENTINEL_FILE}"
    echo "Node setup complete."
fi

echo "Starting Globus Connect Server services..."

# Start GCS manager assistant as gcsweb user in background
echo "Starting GCS manager assistant..."
su -s /bin/bash -c "/usr/sbin/globus-connect-server-web-manager" gcsweb &
GCSWEB_PID=$!

# Start Apache
echo "Starting Apache..."
/usr/sbin/apachectl start

# Start GridFTP server in background
echo "Starting GridFTP server..."
/usr/sbin/globus-gridftp-server \
    -c /etc/gridftp.d \
    -pidfile /var/run/globus-gridftp-server.pid \
    -no-detach &
GRIDFTP_PID=$!

echo "All services started successfully."
echo "GCS manager assistant PID: ${GCSWEB_PID}"
echo "GridFTP server PID: ${GRIDFTP_PID}"

# Monitor processes and exit if any die
monitor_process() {
    local pid=$1
    local name=$2
    
    while kill -0 "${pid}" 2>/dev/null; do
        sleep 5
    done
    
    echo "ERROR: ${name} (PID ${pid}) has died" >&2
    exit 1
}

# Monitor GridFTP in background
monitor_process "${GRIDFTP_PID}" "GridFTP server" &
GRIDFTP_MONITOR_PID=$!

# Monitor GCS web manager in background
monitor_process "${GCSWEB_PID}" "GCS manager assistant" &
GCSWEB_MONITOR_PID=$!

# Monitor Apache (check if it's still running by looking for its master process)
while true; do
    if ! pgrep "apache2" > /dev/null && ! pgrep "httpd" > /dev/null; then
        echo "ERROR: Apache has died" >&2
        exit 1
    fi
    sleep 5
done

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    gnupg \
    apt-transport-https \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Add Globus repository and install globus-connect-server54
RUN wget -q https://downloads.globus.org/globus-connect-server/stable/installers/repo/deb/globus-repo-latest.deb \
    && dpkg -i globus-repo-latest.deb \
    && rm globus-repo-latest.deb \
    && apt-get update \
    && apt-get install -y globus-connect-server54 \
    && rm -rf /var/lib/apt/lists/*

# Copy scripts
COPY scripts/entrypoint.sh /entrypoint.sh
COPY scripts/bootstrap.sh /bootstrap.sh

# Make scripts executable
RUN chmod +x /entrypoint.sh /bootstrap.sh

# Expose ports
EXPOSE 443/tcp
EXPOSE 50000-51000/tcp

# Default entrypoint
ENTRYPOINT ["/entrypoint.sh"]

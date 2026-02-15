# BUILD THE HYTALE SERVER IMAGE
FROM eclipse-temurin:25-jdk

RUN apt-get update && apt-get install -y --no-install-recommends \
    gettext-base \
    procps \
    jq \
    curl \
    gosu \
    unzip \
    wget \
    ca-certificates \
    qemu-user-static \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

LABEL maintainer="support@indifferentbroccoli.com" \
      name="indifferentbroccoli/hytale-server-docker" \
      github="https://github.com/indifferentbroccoli/hytale-server-docker" \
      dockerhub="https://hub.docker.com/r/indifferentbroccoli/hytale-server-docker"

# Create user/group
RUN userdel -r ubuntu 2>/dev/null || true && \
    groupadd -g 1000 hytale && \
    useradd -u 1000 -g 1000 -m -d /home/hytale -s /bin/bash hytale

ENV HOME=/home/hytale \
    CONFIG_DIR=/hytale-config \
    PATH=/home/hytale/server:${PATH} \
    DEFAULT_PORT=5520 \
    SERVER_NAME=hytale-server \
    MAX_PLAYERS=20 \
    VIEW_DISTANCE=12 \
    ENABLE_BACKUPS=false \
    BACKUP_FREQUENCY=30 \
    DISABLE_SENTRY=true \
    USE_AOT_CACHE=true \
    AUTH_MODE=authenticated \
    ACCEPT_EARLY_PLUGINS=false \
    DOWNLOAD_ON_START=true \
    PATCHLINE=release \
    SESSION_TOKEN="" \
    IDENTITY_TOKEN="" \
    OWNER_UUID=""

COPY ./scripts /home/hytale/server/

COPY branding /branding

RUN mkdir -p /home/hytale/server-files && \
    chmod +x /home/hytale/server/*.sh && \
    chown -R 1000:1000 /home/hytale && \
    # Allow running the container as an arbitrary non-root uid (rootless, OpenShift, etc.).
    # With 750 permissions, a non-matching uid cannot even traverse /home/hytale to reach
    # the entrypoint or mounted volume.
    chmod 755 /home/hytale

WORKDIR /home/hytale/server

# Rootless-compatible machine-id persistence
# We cannot write to /etc or /var/lib/dbus when running as non-root.
# Instead we make those paths symlinks to a file stored in the persistent volume.
RUN mkdir -p /home/hytale/server-files/.machine-id /var/lib/dbus && \
    rm -f /etc/machine-id /var/lib/dbus/machine-id && \
    ln -s /home/hytale/server-files/.machine-id/machine-id /etc/machine-id && \
    ln -s /home/hytale/server-files/.machine-id/dbus-machine-id /var/lib/dbus/machine-id

# Health check to ensure the server is running
HEALTHCHECK --start-period=5m \
            --interval=30s \
            --timeout=10s \
            CMD pgrep -f "HytaleServer.jar" > /dev/null || exit 1

ENTRYPOINT ["bash", "/home/hytale/server/init.sh"]

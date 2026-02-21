# BUILD THE HYTALE SERVER IMAGE
FROM eclipse-temurin:25-jdk

# ENVIRONMENT NON USER DEFINED
ENV HOME=/home/hytale \
    USERN=hytale 
ENV SERVER_FILES=${HOME}/server-files SERVER_ROOT=${HOME}/server
ENV CONFIG_DIR=${SERVER_ROOT}/hytale-config \ 
    PATH={SERVER_ROOT}:${PATH} \
    BACKUP_DIR=${SERVER_FILES}/backups 

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
RUN userdel -r ubuntu 2>/dev/null || true \
 && useradd -u 1000 -G sudo -U -m -s /bin/bash ${USERN} \
 && echo "${USERN} ALL=(ALL) NOPASSWD: /bin/chown" >> /etc/sudoers \ 
 && chown -R ${USERN}:${USERN} ${HOME} \
 && chmod 755 ${HOME}


# RUN mkdir /home/hytale 
RUN mkdir -p ${SERVER_ROOT} ${SERVER_FILES} ${BACKUP_DIR}

# Copy some files
COPY --chown=${USERN}:${USERN} ./scripts ${SERVER_ROOT}
COPY --chown=${USERN}:${USERN} branding /branding

# Rootless-compatible machine-id persistence
# We cannot write to /etc or /var/lib/dbus when running as non-root.
# Instead we make those paths symlinks to a file stored in the persistent volume.
RUN mkdir -p ${SERVER_FILES}/.machine-id /var/lib/dbus && \
    rm -f /etc/machine-id /var/lib/dbus/machine-id && \
    ln -s ${SERVER_FILES}/.machine-id/machine-id /etc/machine-id && \
    ln -s ${SERVER_FILES}/.machine-id/dbus-machine-id /var/lib/dbus/machine-id


# RUN chmod +x /home/hytale/server/*.sh && \
#     chown -R hytale:hytale /home/hytale

    
USER ${USERN}

WORKDIR ${SERVER_ROOT}

# Health check to ensure the server is running
HEALTHCHECK --start-period=5m \
            --interval=30s \
            --timeout=10s \
            CMD pgrep -f "HytaleServer.jar" > /dev/null || exit 1

ENTRYPOINT ["/home/hytale/server/init.sh"]

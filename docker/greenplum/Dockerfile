# Stage 1: Builder - all build dependencies and compilation
FROM andruche/greenplum:6.25.3 AS builder

ARG TARGETARCH

# Install build tools and all development libraries
RUN apt-get update && \
    apt-get install -y \
        gcc \
        g++ \
        cmake \
        curl \
        wget \
        openjdk-11-jdk \
        libaprutil1-dev \
        libapr1-dev \
        libbz2-dev \
        libcurl4-gnutls-dev \
        libevent-dev \
        libkrb5-dev \
        libpam-dev \
        libperl-dev \
        libreadline-dev \
        libssl-dev \
        libuv1-dev \
        libxml2-dev \
        libyaml-dev \
        libzstd-dev \
        zlib1g-dev \
        libldap-dev \
        libossp-uuid-dev && \
    rm -rf /var/lib/apt/lists/*

# Install Go
RUN mkdir -p /opt/go && \
    wget https://go.dev/dl/go1.23.4.linux-$TARGETARCH.tar.gz && \
    tar -xvf go1.23.4.linux-$TARGETARCH.tar.gz -C /usr/local && \
    rm go1.23.4.linux-$TARGETARCH.tar.gz

ENV PATH="$PATH:/usr/local/go/bin"
ENV GOPATH=/opt/go

# Set JAVA_HOME for build
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-${TARGETARCH} \
    PATH=$PATH:/usr/lib/jvm/java-11-openjdk-${TARGETARCH}/bin

# Download and extract PXF source
RUN wget https://github.com/woblerr/pxf/archive/refs/tags/release-6.10.1.tar.gz -O /tmp/pxf-release-6.10.1.tar.gz && \
    mkdir -p /tmp/pxf && \
    tar -xzf /tmp/pxf-release-6.10.1.tar.gz --strip-components=1 -C /tmp/pxf

WORKDIR /tmp/pxf

# Build and install PXF (combined into single RUN)
RUN PXF_HOME=/usr/local/pxf PG_CONFIG=/usr/local/gpdb/bin/pg_config make -j2 -C external-table install && \
    PXF_HOME=/usr/local/pxf PG_CONFIG=/usr/local/gpdb/bin/pg_config make -j2 -C cli install && \
    PXF_HOME=/usr/local/pxf PG_CONFIG=/usr/local/gpdb/bin/pg_config make -j2 -C server install-server


# Stage 2: Runtime - only necessary runtime dependencies
FROM andruche/greenplum:6.25.3

ARG TARGETARCH

# Install only Java 11 and runtime libraries (non-dev versions)
RUN apt-get update && \
    apt-get install -y \
        openjdk-11-jdk \
        gosu \
        libaprutil1 \
        libapr1 \
        libbz2-1.0 \
        libcurl4 \
        libevent-2.1-7 \
        libkrb5-3 \
        libpam0g \
        libreadline8 \
        libssl3 \
        libuv1 \
        libxml2 \
        libyaml-0-2 \
        libzstd1 \
        zlib1g \
        libldap-2.5-0 \
        curl \
        libossp-uuid16 && \
    rm -rf /var/lib/apt/lists/*

# Copy compiled PXF from builder
COPY --from=builder /usr/local/pxf /usr/local/pxf

# CRITICAL: Copy PXF extension files to Greenplum directories
COPY --from=builder /usr/local/gpdb/lib/postgresql/pxf.so /usr/local/gpdb/lib/postgresql/pxf.so
COPY --from=builder /usr/local/gpdb/share/postgresql/extension/pxf* /usr/local/gpdb/share/postgresql/extension/

# Configure PXF environment variables
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-${TARGETARCH} \
    PATH=$PATH:/usr/lib/jvm/java-11-openjdk-${TARGETARCH}/bin
    
ENV PXF_HOME=/usr/local/pxf \
    PXF_BASE=/data/pxf \
    PATH=$PATH:/usr/local/pxf/bin

# Add PXF paths to gpadmin user profile
RUN echo 'export PXF_HOME=/usr/local/pxf' >> /home/gpadmin/.bashrc && \
    echo 'export PXF_BASE=/data/pxf' >> /home/gpadmin/.bashrc && \
    echo 'export PATH=$PATH:$PXF_HOME/bin' >> /home/gpadmin/.bashrc

# Create PXF base directory with proper ownership
RUN mkdir -p /data/pxf /data/greenplum && \
    chown -R gpadmin:gpadmin /data


COPY --chown=gpadmin:gpadmin configure-logs.sh /configure-logs.sh
RUN chmod +x /configure-logs.sh

# Copy custom entrypoint
COPY --chown=gpadmin:gpadmin docker-entrypoint-pxf.sh /docker-entrypoint-pxf.sh
RUN sed -i 's/\r//' /docker-entrypoint-pxf.sh && chmod +x /docker-entrypoint-pxf.sh

# Declare persistent volumes
VOLUME ["/data/greenplum", "/data/pxf"]

# Expose Greenplum coordinator (5432) and PXF service (5888)
EXPOSE 5432 5888

USER gpadmin
WORKDIR /home/gpadmin

ENTRYPOINT ["/docker-entrypoint-pxf.sh"]
CMD ["run"]
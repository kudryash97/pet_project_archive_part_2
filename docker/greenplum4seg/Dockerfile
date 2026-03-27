# =============================================================================
# Stage 1: Build Greenplum from source
# =============================================================================
FROM ubuntu:22.04 AS gpdb_builder

SHELL ["/bin/bash", "-c"]
RUN echo 'alias ll="ls -l"' >> /root/.bashrc
RUN echo 'export PS1="\[\033[1;36m\][\u@\h \W]\[\033[0;31m\]$\[\033[0;37m\] "' >> /root/.bashrc

# Install Greenplum build dependencies
RUN --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
    --mount=target=/var/cache/apt,type=cache,sharing=locked \
    rm -f /etc/apt/apt.conf.d/docker-clean \
    && apt-get update \
    && apt-get -y install \
        bison ccache cmake curl flex git-core gcc g++ inetutils-ping libapr1-dev libbz2-dev \
        libcurl4-gnutls-dev libevent-dev libkrb5-dev libpam-dev libperl-dev libreadline-dev \
        libssl-dev libxml2-dev libyaml-dev libzstd-dev locales net-tools ninja-build \
        openssh-client openssh-server openssl zlib1g-dev libldap-dev libossp-uuid-dev \
        vim wget mc sudo iproute2 \
        python2.7 python2.7-dev \
    && export DEBIAN_FRONTEND=noninteractive && apt-get install -y krb5-kdc krb5-admin-server

RUN curl https://bootstrap.pypa.io/pip/2.7/get-pip.py --output /tmp/get-pip.py && python2.7 /tmp/get-pip.py
RUN pip2.7 install PyYAML==5.3.1 conan==1.48.2 psutil==5.9.6
RUN ln -s /usr/bin/python2.7 /usr/bin/python

# Install pathed version of xerces-c
WORKDIR /opt/
RUN --mount=target=/opt/cache,type=cache,sharing=locked \
    cd /opt/cache && \
    [ -f gp-xerces-main.zip ] || wget https://github.com/greenplum-db/gp-xerces-archive/archive/refs/heads/main.zip -O gp-xerces-main.zip && \
    unzip gp-xerces-main.zip -d /opt/

WORKDIR /opt/gp-xerces-archive-main
RUN ./configure --prefix=/usr/local && make -j 4 && make install

# Download and build Greenplum
WORKDIR /opt/
RUN --mount=target=/opt/cache,type=cache,sharing=locked \
    cd /opt/cache && \
    [ -f gpdb-6.25.3.zip ] || wget https://github.com/greenplum-db/gpdb-archive/archive/367edc6b4dfd909fe38fc288ade9e294d74e3f9a.zip -O gpdb-6.25.3.zip && \
    unzip gpdb-6.25.3.zip -d /opt/ && \
    mv /opt/gpdb-archive-367edc6b4dfd909fe38fc288ade9e294d74e3f9a /opt/gpdb-6.25.3

WORKDIR /opt/gpdb-6.25.3
RUN echo "6.25.3 build dev" > ./VERSION
RUN ./configure --with-orca --with-libxml --with-uuid=ossp --with-ldap --with-openssl \
      --enable-gpfdist --with-gssapi --with-zstd --prefix=/usr/local/gpdb
RUN make -j 4
RUN make install

# Build bitmap_bucket extension
WORKDIR /opt/
RUN wget https://github.com/comagic/greenplum_bitmap_bucket/archive/refs/heads/main.zip && \
    unzip main.zip -d /opt/ && mv greenplum_bitmap_bucket-main bitmap_bucket

# =============================================================================
# Stage 2: Build PXF
# =============================================================================
FROM gpdb_builder AS pxf_builder

ARG TARGETARCH

# Install PXF build dependencies
RUN apt-get update && \
    apt-get install -y \
        openjdk-11-jdk && \
    rm -rf /var/lib/apt/lists/*

# Install Go
RUN mkdir -p /opt/go && \
    wget https://go.dev/dl/go1.23.4.linux-${TARGETARCH:-amd64}.tar.gz && \
    tar -xvf go1.23.4.linux-${TARGETARCH:-amd64}.tar.gz -C /usr/local && \
    rm go1.23.4.linux-${TARGETARCH:-amd64}.tar.gz

ENV PATH="$PATH:/usr/local/go/bin"
ENV GOPATH=/opt/go
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-${TARGETARCH:-amd64} \
    PATH=$PATH:/usr/lib/jvm/java-11-openjdk-${TARGETARCH:-amd64}/bin

# Download and build PXF
RUN wget https://github.com/woblerr/pxf/archive/refs/tags/release-6.10.1.tar.gz -O /tmp/pxf-release-6.10.1.tar.gz && \
    mkdir -p /tmp/pxf && \
    tar -xzf /tmp/pxf-release-6.10.1.tar.gz --strip-components=1 -C /tmp/pxf

WORKDIR /tmp/pxf

RUN PXF_HOME=/usr/local/pxf PG_CONFIG=/usr/local/gpdb/bin/pg_config make -j2 -C external-table install && \
    PXF_HOME=/usr/local/pxf PG_CONFIG=/usr/local/gpdb/bin/pg_config make -j2 -C cli install && \
    PXF_HOME=/usr/local/pxf PG_CONFIG=/usr/local/gpdb/bin/pg_config make -j2 -C server install-server

# =============================================================================
# Stage 3: Runtime image with configurable segment count
# =============================================================================
FROM ubuntu:22.04 AS runtime

ARG TARGETARCH

SHELL ["/bin/bash", "-c"]
RUN echo 'alias ll="ls -l"' >> /root/.bashrc
RUN echo 'export PS1="\[\033[1;36m\][\u@\h \W]\[\033[0;31m\]$\[\033[0;37m\] "' >> /root/.bashrc

# Install runtime dependencies
RUN --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
    --mount=target=/var/cache/apt,type=cache,sharing=locked \
    rm -f /etc/apt/apt.conf.d/docker-clean && \
    apt-get update && \
    apt-get -y install \
      make python2.7 openssh-client openssh-server openssl sudo iproute2 \
      net-tools less inetutils-ping locales libcurl3-gnutls \
      openjdk-11-jdk gosu \
      libaprutil1 libapr1 libbz2-1.0 libcurl4 libevent-2.1-7 libkrb5-3 \
      libpam0g libreadline8 libssl3 libuv1 libxml2 libyaml-0-2 libzstd1 \
      zlib1g libldap-2.5-0 curl libossp-uuid16

WORKDIR /opt/
RUN ln -s /usr/bin/python2.7 /usr/bin/python
COPY --from=pxf_builder /usr/local/lib/python2.7/dist-packages/psutil /usr/local/lib/python2.7/dist-packages/psutil

# Build locale en_US.UTF-8
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

# Copy xerces library
RUN --mount=from=pxf_builder,source=/usr/local/lib,target=/opt/builder_local_lib/ \
    cd /opt/builder_local_lib/ && \
    cp libxerces-c-3.1.so libxerces-c.a libxerces-c.la libxerces-c.so /usr/local/lib/
RUN echo /usr/local/lib >> /etc/ld.so.conf.d/custom_libs.conf && ldconfig

# Install Greenplum
RUN --mount=from=pxf_builder,type=bind,source=/opt/gpdb-6.25.3,target=/opt/gpdb-6.25.3,readwrite \
    cd /opt/gpdb-6.25.3 && make install

# Install bitmap_bucket extension
RUN --mount=from=pxf_builder,source=/opt/bitmap_bucket,target=/opt/bitmap_bucket,readwrite \
     cd /opt/bitmap_bucket && make install

# Copy compiled PXF from builder
COPY --from=pxf_builder /usr/local/pxf /usr/local/pxf
COPY --from=pxf_builder /usr/local/gpdb/lib/postgresql/pxf.so /usr/local/gpdb/lib/postgresql/pxf.so
COPY --from=pxf_builder /usr/local/gpdb/share/postgresql/extension/pxf* /usr/local/gpdb/share/postgresql/extension/

# Configure PXF environment
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-${TARGETARCH:-amd64} \
    PATH=$PATH:/usr/lib/jvm/java-11-openjdk-${TARGETARCH:-amd64}/bin

ENV PXF_HOME=/usr/local/pxf \
    PXF_BASE=/data/pxf \
    PATH=$PATH:/usr/local/pxf/bin

# =============================================================================
# Greenplum initialization with configurable SEGMENT_COUNT
# =============================================================================

# SEGMENT_COUNT can be set at build time to configure number of segments (default: 4)
ARG SEGMENT_COUNT=4
RUN mkdir /data \
 && mkdir /data/master \
 && source /usr/local/gpdb/greenplum_path.sh \
 && cp $GPHOME/docs/cli_help/gpconfigs/gpinitsystem_singlenode /data/ \
 && sed -i 's/gpmaster/data\/master/g' /data/gpinitsystem_singlenode

# Create segment data directories based on SEGMENT_COUNT
# and update gpinitsystem_singlenode config with the appropriate DATA_DIRECTORY array
ARG SEGMENT_COUNT
RUN bash -c ' \
    SEGMENT_COUNT=${SEGMENT_COUNT:-4}; \
    if ! [[ "$SEGMENT_COUNT" =~ ^[0-9]+$ ]] || [ "$SEGMENT_COUNT" -lt 1 ] || [ "$SEGMENT_COUNT" -gt 16 ]; then \
        echo "Error: SEGMENT_COUNT must be a number between 1 and 16" >&2; \
        exit 1; \
    fi; \
    echo "Configuring Greenplum with $SEGMENT_COUNT segment(s)"; \
    \
    for i in $(seq 1 $SEGMENT_COUNT); do \
        mkdir -p /data/data$i; \
    done; \
    \
    declare -a dirs; \
    for i in $(seq 1 $SEGMENT_COUNT); do \
        dirs+=("/data/data$i"); \
    done; \
    \
    dirs_string=$(printf " %s" "${dirs[@]}"); \
    dirs_string=${dirs_string:1}; \
    \
    sed -i "s|^declare -a DATA_DIRECTORY=.*|declare -a DATA_DIRECTORY=($dirs_string)|" /data/gpinitsystem_singlenode \
'

# Create gpadmin user and add to sudoers
RUN useradd -md /home/gpadmin/ --shell /bin/bash gpadmin \
 && chown gpadmin -R /data \
 && echo "source /usr/local/gpdb/greenplum_path.sh" > /home/gpadmin/.bash_profile \
 && echo 'export PS1="\[\033[1;35m\][\u@\h \W]\[\033[0;31m\]$\[\033[0;37m\] "'  >> /home/gpadmin/.bash_profile \
 && echo 'export MASTER_DATA_DIRECTORY="/data/master/gpsne-1/"'  >> /home/gpadmin/.bash_profile \
 && echo 'alias ll="ls -l"'  >> /home/gpadmin/.bash_profile \
 && echo 'export PXF_HOME=/usr/local/pxf' >> /home/gpadmin/.bash_profile \
 && echo 'export PXF_BASE=/data/pxf' >> /home/gpadmin/.bash_profile \
 && echo 'export PATH=$PATH:$PXF_HOME/bin' >> /home/gpadmin/.bash_profile \
 && chown gpadmin:gpadmin /home/gpadmin/.bash_profile \
 && su - gpadmin bash -c 'mkdir /home/gpadmin/.ssh' \
 && echo "gpadmin ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers \
 && echo "root ALL=NOPASSWD: ALL" >> /etc/sudoers

RUN mkdir /run/sshd
RUN echo "set hlsearch" >> /home/gpadmin/.vimrc

# Generate SSH keys for gpadmin
RUN su - gpadmin bash -c '\
    ssh-keygen -f /home/gpadmin/.ssh/id_rsa -t rsa -N "" && \
    cp /home/gpadmin/.ssh/id_rsa.pub /home/gpadmin/.ssh/authorized_keys && \
    chmod 600 /home/gpadmin/.ssh/authorized_keys'

# Workaround to set host=localhost for master node
RUN echo "def gethostname(): return 'localhost'" >> /usr/lib/python2.7/socket.py
RUN mv /usr/bin/hostname{,.bkp} && \
  echo "echo localhost" > /usr/bin/hostname && \
  chmod +x /usr/bin/hostname && \
  echo localhost > /etc/hostname

# Initialize Greenplum cluster
RUN su - gpadmin bash -c '\
    cd /data/ && \
    echo "starting sshd ..." && \
    sudo /etc/init.d/ssh start && \
    sleep 2 && \
    ssh -o StrictHostKeyChecking=no localhost ls && \
    ssh -o StrictHostKeyChecking=no `hostname` ls && \
    source /home/gpadmin/.bash_profile && \
    echo localhost > /data/hostlist_singlenode && \
    sed -i "s/hostname_of_machine/localhost/g" /data/gpinitsystem_singlenode && \
    echo "gpssh-exkeys ..." && \
    gpssh-exkeys -f /data/hostlist_singlenode && \
    echo "gpinitsystem ..." && \
    gpinitsystem --ignore-warnings -ac gpinitsystem_singlenode && \
    echo "host all  all 0.0.0.0/0 trust" >> /data/master/gpsne-1/pg_hba.conf && \
    echo "host all  all ::0/0 trust" >> /data/master/gpsne-1/pg_hba.conf && \
    psql -d postgres -c "alter role gpadmin with password \$\$123456\$\$" && \
    echo "gpstop ..." && \
    gpstop -a'

RUN mv /usr/bin/hostname{.bkp,}

# Create PXF base directory
RUN mkdir -p /data/pxf /data/greenplum && \
    chown -R gpadmin:gpadmin /data

# Copy configuration scripts
COPY --chown=gpadmin:gpadmin configure-logs.sh /configure-logs.sh
RUN chmod +x /configure-logs.sh

COPY --chown=gpadmin:gpadmin docker-entrypoint-pxf.sh /docker-entrypoint-pxf.sh
RUN chmod +x /docker-entrypoint-pxf.sh

# Declare persistent volumes
VOLUME ["/data/greenplum", "/data/pxf"]

# Expose Greenplum coordinator (5432) and PXF service (5888)
EXPOSE 5432 5888

USER gpadmin
WORKDIR /home/gpadmin

ENTRYPOINT ["/docker-entrypoint-pxf.sh"]
CMD ["run"]
#!/bin/bash
# docker-entrypoint-pxf.sh - Orchestrates Greenplum + PXF startup
set -e

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

# Initialize PXF on first run only
initialize_pxf() {
    mkdir -p $PXF_BASE/conf $PXF_BASE/run $PXF_BASE/logs

    # ALWAYS regenerate pxf-env.sh to ensure correct JAVA_HOME
    log "Configuring PXF environment"
    cat > $PXF_BASE/conf/pxf-env.sh << EOF
export JAVA_HOME=$JAVA_HOME
export PXF_JVM_OPTS="-Xmx512m -Xms256m"
export PXF_MAX_THREADS=96
EOF

    # Skip full init if already done
    if [ -f "$PXF_BASE/conf/pxf-application.properties" ]; then
        log "PXF already initialized, config updated"
        return 0
    fi

    log "Initializing PXF"
    # Copy default configuration files from PXF_HOME
    if [ -f "$PXF_HOME/conf/pxf-application.properties" ]; then
        cp "$PXF_HOME/conf/pxf-application.properties" "$PXF_BASE/conf/"
        log "Copied pxf-application.properties"
    fi

    if [ -f "$PXF_HOME/conf/pxf-log4j2.xml" ]; then
        cp "$PXF_HOME/conf/pxf-log4j2.xml" "$PXF_BASE/conf/"
        log "Copied pxf-log4j2.xml"
    fi

    # Run PXF initialization (may be deprecated but try anyway)
    source /usr/local/gpdb/greenplum_path.sh
    $PXF_HOME/bin/pxf init || log "pxf init skipped (deprecated)"

    # Register PXF extension with Greenplum
    $PXF_HOME/bin/pxf register || log "PXF register skipped (run manually on master)"

    log "PXF initialization complete"
}

# Configure Yandex Cloud S3 server for anonymous access
configure_yandex_s3() {
    local server_dir="$PXF_BASE/servers/yandex-public"
    
    if [ -d "$server_dir" ]; then
        log "Yandex S3 server already configured"
        return 0
    fi
    
    log "Configuring Yandex Cloud S3 server"
    mkdir -p "$server_dir"
    
    cat > "$server_dir/s3-site.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <property>
        <name>fs.s3a.endpoint</name>
        <value>storage.yandexcloud.net</value>
    </property>
    <property>
        <name>fs.s3a.aws.credentials.provider</name>
        <value>org.apache.hadoop.fs.s3a.AnonymousAWSCredentialsProvider</value>
    </property>
    <property>
        <name>fs.s3a.path.style.access</name>
        <value>true</value>
    </property>
    <property>
        <name>fs.s3a.connection.maximum</name>
        <value>96</value>
    </property>
    <property>
        <name>fs.s3a.impl</name>
        <value>org.apache.hadoop.fs.s3a.S3AFileSystem</value>
    </property>
</configuration>
EOF
    
    log "Yandex S3 server configured at: $server_dir"
}

# Start PXF service
start_pxf_service() {
    log "Starting PXF service"

    source /usr/local/gpdb/greenplum_path.sh

    # Clean up stale PID file if exists
    if [ -f "$PXF_BASE/run/pxf-app.pid" ]; then
        log "Cleaning up stale PXF PID file"
        rm -f "$PXF_BASE/run/pxf-app.pid"
    fi

    $PXF_HOME/bin/pxf start || log "WARNING: PXF start command failed"

    sleep 3
    if $PXF_HOME/bin/pxf status > /dev/null 2>&1; then
        log "PXF service running on port 5888"
    else
        log "WARNING: PXF service may have failed to start"
        cat $PXF_BASE/logs/pxf-service.log || true
    fi
}

configure_log_rotation() {
    log "Configuring log rotation"
    /configure-logs.sh
}

# Start Greenplum Database
start_greenplum() {
    log "Starting Greenplum Database"

    # Start SSH (required for Greenplum inter-process communication)
    sudo /etc/init.d/ssh start 2>/dev/null || /usr/sbin/sshd 2>/dev/null || log "SSH may already be running"
    sleep 2

    # Set Greenplum environment variables
    export MASTER_DATA_DIRECTORY=/data/master/gpsne-1

    # Start Greenplum cluster
    source /usr/local/gpdb/greenplum_path.sh
    gpstart -a

    log "Greenplum start command issued"
}

# Wait for Greenplum to be ready
wait_for_greenplum() {
    log "Waiting for Greenplum Database"
    
    local max_attempts=30
    local attempt=0
    
    while ! pg_isready -h localhost -p 5432 -U gpadmin > /dev/null 2>&1; do
        attempt=$((attempt + 1))
        if [ $attempt -ge $max_attempts ]; then
            log "ERROR: Greenplum did not start within timeout"
            return 1
        fi
        sleep 2
    done
    
    log "Greenplum is ready"
}

# Setup PXF extension in databases
setup_pxf_extension() {
    log "Setting up PXF extension in databases"
    
    # Create in template1 (inherited by new databases)
    psql -d template1 -c "CREATE EXTENSION IF NOT EXISTS pxf;" 2>/dev/null || true
    
    # Create in existing user databases
    # psql -t -c "SELECT datname FROM pg_database WHERE datname NOT IN ('template0', 'template1', 'postgres');" | \
    # while read -r db; do
    #     db=$(echo "$db" | xargs)
    #     if [ -n "$db" ]; then
    #         log "Creating PXF extension in: $db"
    #         psql -d "$db" -c "CREATE EXTENSION IF NOT EXISTS pxf;" 2>/dev/null || true
    #     fi
    # done
}

# Main execution flow
main() {
    log "=== Greenplum + PXF Educational Container ==="
    
    # Initialize PXF (first run)
    initialize_pxf
    
    # Configure Yandex Cloud S3
    configure_yandex_s3

    configure_log_rotation

    # Start Greenplum
    start_greenplum

    # Wait for database readiness
    wait_for_greenplum
    
    # Start PXF service
    start_pxf_service
    
    # Setup extensions
    setup_pxf_extension
    
    log "=== Startup complete ==="
    log "Greenplum: localhost:5432 | PXF: localhost:5888"
    
    # Keep container running and tail all Greenplum logs to stdout
    log() {
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
    }

    log "Starting log tailing to container stdout..."
    log "Master logs: /data/master/gpsne-1/pg_log/"
    log "Segment 0 logs: /data/data1/gpsne0/pg_log/"
    log "Segment 1 logs: /data/data2/gpsne1/pg_log/"

    # Tail all CSV log files from master and segments
    # -F follows files even if they're rotated
    # 2>&1 sends stderr to stdout so Docker captures everything
    tail -F \
        /data/master/gpsne-1/pg_log/*.csv \
        /data/data1/gpsne0/pg_log/*.csv \
        /data/data2/gpsne1/pg_log/*.csv \
        2>&1 &

    TAIL_PID=$!
    log "Log tailing started (PID: $TAIL_PID)"

    # Wait for the tail process (keeps container alive)
    wait $TAIL_PID
}

# Handle graceful shutdown
trap "log 'Shutting down...'; $PXF_HOME/bin/pxf stop 2>/dev/null || true; exit 0" SIGTERM SIGINT

main
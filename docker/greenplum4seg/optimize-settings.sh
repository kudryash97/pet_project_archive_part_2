#!/bin/bash
# Production OLAP settings for 4-segment single-host Greenplum
# Resources: 20GB RAM, 10 CPU cores
# Usage: Run after cluster startup to apply optimized settings

docker exec -u gpadmin greenplum4seg bash -c '
export USER=gpadmin
export MASTER_DATA_DIRECTORY=/data/master/gpsne-1
source /usr/local/gpdb/greenplum_path.sh

echo "=== Applying production OLAP settings ==="

gpconfig -c shared_buffers -v 16384
gpconfig -c statement_mem -v 512000
gpconfig -c max_statement_mem -v 2048000
gpconfig -c gp_vmem_protect_limit -v 4096
gpconfig -c gp_workfile_limit_per_query -v 5242880
gpconfig -c gp_workfile_limit_per_segment -v 10485760
gpconfig -c gp_enable_relsize_collection -v on
gpconfig -c gp_autostats_mode -v on_no_stats
gpconfig -c log_min_duration_statement -v 10000
gpconfig -c gp_enable_query_metrics -v on

gpstop -ar
'
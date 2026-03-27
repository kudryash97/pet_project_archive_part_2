#!/bin/bash
set -e

echo "=== Nginx Certificate Reload - $(date) ===" 

cd /home/lexxa/rzv_de_project_online

echo "Reloading nginx to pick up any renewed certificates..."
docker compose exec nginx nginx -s reload

echo "Nginx reloaded successfully"
echo "=== Completed - $(date) ==="
echo ""

exit 0

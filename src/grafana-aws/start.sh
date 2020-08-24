#!/bin/bash

[ "$TRACE" = "yes" ] && set -x
set -e

echo "Running grafana."
exec /opt/grafana/bin/grafana-server \
    --homepath="/opt/grafana" \
    --config="/opt/grafana/conf/grafana.ini"

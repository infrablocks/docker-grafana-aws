#!/bin/bash

[ "$TRACE" = "yes" ] && set -x
set -e

echo "Running grafana."
exec /opt/grafana/bin/grafana-server \
    --homepath="$GRAFANA_PATHS_HOME" \
    --config="$GRAFANA_PATHS_CONFIG" \
    --packaging="docker" \
    "$@" \
    cfg:default.log.mode="console" \
    cfg:default.paths.data="$GRAFANA_PATHS_DATA" \
    cfg:default.paths.logs="$GRAFANA_PATHS_LOGS" \
    cfg:default.paths.plugins="$GRAFANA_PATHS_PLUGINS" \
    cfg:default.paths.provisioning="$GRAFANA_PATHS_PROVISIONING"

#!/bin/bash

[ "$TRACE" = "yes" ] && set -x
set -e

permissions_ok=0

if [ ! -r "$GRAFANA_PATHS_CONFIG" ]; then
    echo "Error: GRAFANA_PATHS_CONFIG='$GRAFANA_PATHS_CONFIG' is not readable."
    permissions_ok=1
fi

if [ ! -w "$GRAFANA_PATHS_DATA" ]; then
    echo "Error: GRAFANA_PATHS_DATA='$GRAFANA_PATHS_DATA' is not writable."
    permissions_ok=1
fi

if [ ! -w "$GRAFANA_PATHS_HOME" ]; then
    echo "Error: GRAFANA_PATHS_HOME='$GRAFANA_PATHS_HOME' is not readable."
    permissions_ok=1
fi

if [ $permissions_ok -eq 1 ]; then
    exit
fi

echo "Running grafana."
exec /opt/grafana/bin/grafana-server \
    --homepath="$GRAFANA_PATHS_HOME" \
    --config="$GRAFANA_PATHS_CONFIG" \
    --packaging="docker" \
    "$@" \
    cfg:default.log.mode="console" \
    cfg:default.log.console.format="json" \
    cfg:default.paths.data="$GRAFANA_PATHS_DATA" \
    cfg:default.paths.logs="$GRAFANA_PATHS_LOGS" \
    cfg:default.paths.plugins="$GRAFANA_PATHS_PLUGINS" \
    cfg:default.paths.provisioning="$GRAFANA_PATHS_PROVISIONING"

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
    exit 1
fi

if [ -n "${GRAFANA_AWS_PROFILES+x}" ]; then
    credentials_path="$GRAFANA_PATHS_HOME/.aws/credentials"

    cat /dev/null > "$credentials_path"

    for profile in ${GRAFANA_AWS_PROFILES//,/ }; do
        access_key_id_var_name="GRAFANA_AWS_${profile}_ACCESS_KEY_ID"
        secret_access_key_var_name="GRAFANA_AWS_${profile}_SECRET_ACCESS_KEY"
        region_var_name="GRAFANA_AWS_${profile}_REGION"

        if [[ -n "${!access_key_id_var_name}" && -n "${!secret_access_key_var_name}" ]]; then
            {
                echo "[${profile}]";
                echo "aws_access_key_id = ${!access_key_id_var_name}"
                echo "aws_secret_access_key = ${!secret_access_key_var_name}"
            } >> "$credentials_path"
            if [ -n "${!region_var_name}" ]; then
                echo "region = ${!region_var_name}" >> "$credentials_path"
            fi
        fi
    done

    chmod 600 "$credentials_path"
fi

for var_name in $(env | grep '^GRAFANA_[^=]\+__FILE=.\+' | sed -r "s/([^=]*)__FILE=.*/\1/g"); do
    var_file_var_name="$var_name"__FILE
    if [ "${!var_name}" ]; then
        echo >&2 "Error: Both $var_name and $var_file_var_name are set (but are exclusive)."
        exit 1
    fi
    export "$var_name"="$(< "${!var_file_var_name}")"
    unset "$var_file_var_name"
done

if [ ! -d "$GRAFANA_PATHS_PLUGINS" ]; then
    mkdir -p "$GRAFANA_PATHS_PLUGINS"
fi

if [ -n "${GRAFANA_INSTALL_PLUGINS}" ]; then
    for plugin in ${GRAFANA_INSTALL_PLUGINS//,/ }; do
        if [[ $plugin =~ .*\;.* ]]; then
          plugin_url=$(echo "$plugin" | cut -d';' -f 1)
          plugin_without_url=$(echo "$plugin" | cut -d';' -f 2)

          /opt/grafana/bin/grafana-cli \
              --pluginsDir "${GRAFANA_PATHS_PLUGINS}" \
              --pluginUrl "${plugin_url}" \
              plugins \
              install \
              "${plugin_without_url}"
        else
          /opt/grafana/bin/grafana-cli \
              --pluginsDir "${GRAFANA_PATHS_PLUGINS}" \
              plugins \
              install \
              "${plugin}"
        fi
    done
fi

export HOME="$GRAFANA_PATHS_HOME"

for var_name in ${!GRAFANA@}; do
    export GF"${var_name#GRAFANA}"="${!var_name}"
done

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

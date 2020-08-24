ARG WITH_GRAFANA_VERSION="7.1.4"
ARG WITH_GRAFANA_UID="472"
ARG WITH_GRAFANA_GID="472"

FROM grafana/grafana:${WITH_GRAFANA_VERSION} as src-builder

FROM infrablocks/alpine-aws-s3-config:0.20.0

ARG WITH_GRAFANA_VERSION
ARG WITH_GRAFANA_UID
ARG WITH_GRAFANA_GID

ENV GRAFANA_VERSION=${WITH_GRAFANA_VERSION} \
    GRAFANA_PATHS_HOME="/opt/grafana" \
    GRAFANA_PATHS_PLUGINS="/opt/grafana/plugins" \
    GRAFANA_PATHS_PROVISIONING="/opt/grafana/provisioning" \
    GRAFANA_PATHS_CONFIG="/opt/grafana/conf/grafana.ini" \
    GRAFANA_PATHS_DATA="/var/opt/grafana" \
    GRAFANA_PATHS_LOGS="/var/log/grafana"

COPY --from=src-builder \
    /usr/share/grafana \
    "$GRAFANA_PATHS_HOME"

RUN apk \
    --verbose \
    --no-cache \
    add \
        openssl \
        tzdata

RUN addgroup -S -g $WITH_GRAFANA_GID grafana && \
    adduser -S -u $WITH_GRAFANA_UID -G grafana grafana

RUN mkdir -p \
        "$GRAFANA_PATHS_PROVISIONING/datasources" \
        "$GRAFANA_PATHS_PROVISIONING/dashboards" \
        "$GRAFANA_PATHS_PROVISIONING/notifiers" \
        "$GRAFANA_PATHS_PROVISIONING/plugins" \
        "$GRAFANA_PATHS_LOGS" \
        "$GRAFANA_PATHS_PLUGINS" \
        "$GRAFANA_PATHS_DATA" && \
    cp \
        "$GRAFANA_PATHS_HOME/conf/sample.ini" \
        "$GRAFANA_PATHS_HOME/conf/grafana.ini" && \
    chown -R grafana:grafana \
        "$GRAFANA_PATHS_HOME" \
        "$GRAFANA_PATHS_PROVISIONING" \
        "$GRAFANA_PATHS_LOGS" \
        "$GRAFANA_PATHS_PLUGINS" \
        "$GRAFANA_PATHS_DATA" && \
    chmod -R 777 \
        "$GRAFANA_PATHS_PROVISIONING" \
        "$GRAFANA_PATHS_LOGS" \
        "$GRAFANA_PATHS_PLUGINS" \
        "$GRAFANA_PATHS_DATA"

COPY start.sh "$GRAFANA_PATHS_HOME/bin/start.sh"

RUN chmod +x "$GRAFANA_PATHS_HOME/bin/start.sh"

EXPOSE 3000

USER grafana

ENV STARTUP_SCRIPT_PATH="$GRAFANA_PATHS_HOME/bin/start.sh"

ARG WITH_GRAFANA_VERSION="7.1.4"

FROM grafana/grafana:${WITH_GRAFANA_VERSION} as src-builder

FROM infrablocks/alpine-aws-s3-config:0.20.0

ARG WITH_GRAFANA_VERSION

ENV GRAFANA_VERSION=${WITH_GRAFANA_VERSION}

COPY --from=src-builder \
    /usr/share/grafana \
    /opt/grafana

COPY docker-entrypoint.sh /opt/grafana/docker-entrypoint.sh

RUN ["chmod", "+x", "/opt/grafana/docker-entrypoint.sh"]

ENV STARTUP_SCRIPT_PATH=/opt/grafana/docker-entrypoint.sh

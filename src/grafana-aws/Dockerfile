ARG WITH_GRAFANA_VERSION="7.1.4"
ARG WITH_GRAFANA_UID="472"
ARG WITH_GRAFANA_GID="472"

FROM grafana/grafana:${WITH_GRAFANA_VERSION} as src-builder

FROM infrablocks/alpine-aws-s3-config:0.20.0

ARG WITH_GRAFANA_VERSION
ARG WITH_GRAFANA_UID
ARG WITH_GRAFANA_GID

ENV GRAFANA_VERSION=${WITH_GRAFANA_VERSION}

COPY --from=src-builder \
    /usr/share/grafana \
    /opt/grafana

RUN addgroup -S -g $WITH_GRAFANA_GID grafana && \
    adduser -S -u $WITH_GRAFANA_UID -G grafana grafana

RUN cp /opt/grafana/conf/sample.ini /opt/grafana/conf/grafana.ini

RUN chown -R grafana:grafana /opt/grafana

COPY start.sh /opt/grafana/bin/start.sh

RUN chmod +x /opt/grafana/bin/start.sh

EXPOSE 3000

USER grafana

ENV STARTUP_SCRIPT_PATH=/opt/grafana/bin/start.sh

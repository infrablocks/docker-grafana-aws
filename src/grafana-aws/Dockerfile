FROM infrablocks/alpine-aws-s3-config:0.18.0

ENV GRAFANA_VERSION 7.1.4

wget https://dl.grafana.com/oss/release/grafana-7.1.4.linux-amd64.tar.gz
tar -zxvf grafana-7.1.4.linux-amd64.tar.gz

RUN cd /tmp \
    && curl \
        -L "https://dl.grafana.com/oss/release/grafana-${GRAFANA_VERSION}.linux-amd64.tar.gz" \
        -o "grafana-${GRAFANA_VERSION}.linux-amd64.tar.gz" \
    && tar -zxvf "grafana-${GRAFANA_VERSION}.linux-amd64.tar.gz" \
    && mkdir -p /opt/grafana \
    && cp -R "grafana-${GRAFANA_VERSION}"/* /opt/grafana \
    && rm "grafana-${GRAFANA_VERSION}.linux-amd64.tar.gz" \
    && rm -rf "grafana-${GRAFANA_VERSION}" \
    && cd /

COPY docker-entrypoint.sh /opt/grafana/docker-entrypoint.sh

RUN ["chmod", "+x", "/opt/grafana/docker-entrypoint.sh"]

ENV STARTUP_SCRIPT_PATH=/opt/grafana/docker-entrypoint.sh

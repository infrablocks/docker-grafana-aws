ARG WITH_GRAFANA_VERSION="7.1.4"

FROM alpine:3.12 as src-builder

ARG WITH_GRAFANA_VERSION

ENV GRAFANA_VERSION=${WITH_GRAFANA_VERSION}

RUN apk \
    --verbose \
    --no-cache \
    add \
        curl

RUN cd /tmp \
    && curl \
        -L "https://github.com/grafana/grafana/archive/v${GRAFANA_VERSION}.tar.gz" \
        -o "grafana-${GRAFANA_VERSION}.tar.gz" \
    && tar -zxvf "grafana-${GRAFANA_VERSION}.tar.gz" \
    && mkdir -p /usr/src/grafana \
    && cp -R "grafana-${GRAFANA_VERSION}"/* /usr/src/grafana \
    && cp -R "grafana-${GRAFANA_VERSION}"/.[!.]* /usr/src/grafana \
    && cp -R "grafana-${GRAFANA_VERSION}"/.??* /usr/src/grafana \
    && rm "grafana-${GRAFANA_VERSION}.tar.gz" \
    && rm -rf "grafana-${GRAFANA_VERSION}" \
    && cd /

FROM node:12.18.3-alpine3.12 as js-builder

ENV NODE_ENV production

WORKDIR /usr/src/grafana/

COPY --from=src-builder \
    /usr/src/grafana/package.json \
    /usr/src/grafana/yarn.lock \
    /usr/src/grafana/
COPY --from=src-builder \
    /usr/src/grafana/packages \
    /usr/src/grafana/packages

RUN yarn install --pure-lockfile --no-progress

COPY --from=src-builder \
    /usr/src/grafana/Gruntfile.js \
    /usr/src/grafana/tsconfig.json \
    /usr/src/grafana/.eslintrc \
    /usr/src/grafana/.editorconfig \
    /usr/src/grafana/.browserslistrc \
    /usr/src/grafana/.prettierrc.js \
    /usr/src/grafana/
COPY --from=src-builder \
    /usr/src/grafana/public \
    /usr/src/grafana/public
COPY --from=src-builder \
    /usr/src/grafana/tools \
    /usr/src/grafana/tools
COPY --from=src-builder \
    /usr/src/grafana/scripts \
    /usr/src/grafana/scripts
COPY --from=src-builder \
    /usr/src/grafana/emails \
    /usr/src/grafana/emails

RUN ./node_modules/.bin/grunt build

FROM infrablocks/alpine-aws-s3-config:0.20.0

ARG WITH_GRAFANA_VERSION

ENV GRAFANA_VERSION=${WITH_GRAFANA_VERSION}

COPY --from=js-builder \
    /usr/src/grafana/public \
    /usr/src/grafana/public
COPY --from=js-builder \
    /usr/src/grafana/tools \
    /usr/src/grafana/tools

COPY docker-entrypoint.sh /opt/grafana/docker-entrypoint.sh

RUN ["chmod", "+x", "/opt/grafana/docker-entrypoint.sh"]

ENV STARTUP_SCRIPT_PATH=/opt/grafana/docker-entrypoint.sh

# https://developers.home-assistant.io/docs/add-ons/configuration#add-on-dockerfile
#
# Thin wrapper: BUILD_FROM (set per-arch in build.yaml) is the published,
# multi-arch muness/unified-hifi-control image. This layer only adds the
# Home Assistant add-on labels and a small options.json -> env var shim —
# it does not rebuild the application.
# Default only used for ad-hoc `docker build .` outside the Supervisor;
# build.yaml's per-arch build_from is what the Supervisor actually uses.
ARG BUILD_FROM=docker.io/muness/unified-hifi-control:latest
FROM ${BUILD_FROM}

# Home Assistant build arguments (populated by the Supervisor at build time)
ARG BUILD_ARCH
ARG BUILD_DATE
ARG BUILD_DESCRIPTION
ARG BUILD_NAME
ARG BUILD_REF
ARG BUILD_REPOSITORY
ARG BUILD_VERSION

LABEL \
    io.hass.name="${BUILD_NAME}" \
    io.hass.description="${BUILD_DESCRIPTION}" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version=${BUILD_VERSION} \
    maintainer="Muness Castle <munesscastle@artium.ai>" \
    org.opencontainers.image.title="${BUILD_NAME}" \
    org.opencontainers.image.description="${BUILD_DESCRIPTION}" \
    org.opencontainers.image.source="https://github.com/${BUILD_REPOSITORY}" \
    org.opencontainers.image.created=${BUILD_DATE} \
    org.opencontainers.image.revision=${BUILD_REF} \
    org.opencontainers.image.version=${BUILD_VERSION} \
    org.opencontainers.image.licenses="PolyForm-Noncommercial-1.0.0"

# jq reads the Supervisor-managed /data/options.json; the base image
# (Alpine) doesn't ship it.
RUN apk add --no-cache jq

# UHC_CONFIG_DIR=/data makes settings, provider pairings, and Roon
# extension state persist in the add-on's private, Supervisor-managed
# volume across restarts and version updates.
ENV UHC_CONFIG_DIR=/data

COPY run.sh /run.sh
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]

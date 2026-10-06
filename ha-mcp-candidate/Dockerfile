# Pin the reviewed multi-platform UHC base directly. Supervisor's legacy
# build.yaml parser rejects digest references and otherwise substitutes its
# generic Home Assistant base image.
FROM docker.io/muness/unified-hifi-control@sha256:33c8b030849826cbe7b44c2b3cb884d43743890cbd4c6c086dbd229f704faa6e

# The candidate wrapper reads its small options file without adding any HA
# configuration or Supervisor API access.
RUN apk add --no-cache jq

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
    org.opencontainers.image.source="https://github.com/${BUILD_REPOSITORY}" \
    org.opencontainers.image.revision=${BUILD_REF} \
    org.opencontainers.image.version=${BUILD_VERSION}

COPY run.sh /run-candidate.sh
RUN chmod a+x /run-candidate.sh

CMD ["/run-candidate.sh"]

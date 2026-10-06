# The Supervisor supplies BUILD_FROM from build.yaml.
ARG BUILD_FROM=docker.io/muness/unified-hifi-control@sha256:ba7f7331f8400192e70437a936a85e261f707d8c035ea4023a9b7e2ec6bb007a
FROM ${BUILD_FROM}

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

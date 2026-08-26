#!/bin/sh
# Maps the add-on's Supervisor-managed options (/data/options.json) to the
# environment variables unified-hifi-control reads directly. This image has
# no s6-overlay/bashio (it wraps the plain muness/unified-hifi-control
# runtime image), so the mapping is done by hand with jq.
set -eu

OPTIONS_FILE=/data/options.json

if [ -f "$OPTIONS_FILE" ]; then
    UHC_PORT="$(jq -r '.port // 8088' "$OPTIONS_FILE")"
    RUST_LOG="$(jq -r '.log_level // "info"' "$OPTIONS_FILE")"
    REQUIRE_CONTROLLER_AUTH="$(jq -r '.require_controller_auth // false' "$OPTIONS_FILE")"
else
    echo "run.sh: ${OPTIONS_FILE} not found, using defaults" >&2
    UHC_PORT=8088
    RUST_LOG=info
    REQUIRE_CONTROLLER_AUTH=false
fi

export UHC_PORT
export RUST_LOG

if [ "$REQUIRE_CONTROLLER_AUTH" = "true" ]; then
    export UHC_REQUIRE_CONTROLLER_AUTH=1
fi

# UHC_CONFIG_DIR is already set to /data via the Dockerfile ENV.
exec /app/unified-hifi-control

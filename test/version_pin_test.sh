#!/bin/sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
config_file="$repo_dir/unified-hifi-control/config.yaml"
build_file="$repo_dir/unified-hifi-control/build.yaml"

config_version=$(sed -n 's/^version: *"\([^"]*\)".*/\1/p' "$config_file")
amd64_version=$(sed -n 's|^  amd64: .*:\([^: ]*\)$|\1|p' "$build_file")
aarch64_version=$(sed -n 's|^  aarch64: .*:\([^: ]*\)$|\1|p' "$build_file")

if [ -z "$config_version" ] || [ -z "$amd64_version" ] || [ -z "$aarch64_version" ]; then
    echo "Could not read every add-on/runtime version pin." >&2
    exit 1
fi

if [ "$amd64_version" = latest ] || [ "$aarch64_version" = latest ]; then
    echo "The add-on must pin an immutable UHC image version, never latest." >&2
    exit 1
fi

if [ "$config_version" != "$amd64_version" ] || [ "$config_version" != "$aarch64_version" ]; then
    echo "config.yaml ($config_version) and build.yaml ($amd64_version, $aarch64_version) must match." >&2
    exit 1
fi

echo "Pinned UHC runtime: $config_version (amd64, aarch64)"

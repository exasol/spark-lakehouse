#!/usr/bin/env bash
# Prints the image tag <spark-version>-<format>-<build-number> from the ARG defaults in <format>/Dockerfile.
# Usage: scripts/image-tag.sh iceberg|delta
set -euo pipefail

readonly format="${1:?usage: $0 iceberg|delta}"
readonly dockerfile="$(dirname "$0")/../${format}/Dockerfile"

arg_default() {
    sed -n "s/^ARG $1=//p" "$dockerfile"
}

[[ -f "$dockerfile" ]] || { echo "No Dockerfile for format '$format': $dockerfile" >&2; exit 2; }
readonly spark_version="$(arg_default SPARK_VERSION)"
readonly build_number="$(arg_default IMAGE_BUILD_NUMBER)"
[[ -n "$spark_version" ]] || { echo "No 'ARG SPARK_VERSION=' default in $dockerfile" >&2; exit 1; }
[[ "$build_number" =~ ^[1-9][0-9]*$ ]] || { echo "Missing or invalid 'ARG IMAGE_BUILD_NUMBER=' default in $dockerfile" >&2; exit 1; }

echo "${spark_version}-${format}-${build_number}"

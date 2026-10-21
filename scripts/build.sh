#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKETCH="${ROOT}/simpleOTA-starter-arduino"
BUILD="${ROOT}/build"

CORE_VERSION="3.3.12"
LIB_VERSION="0.5.0"
FQBN="esp32:esp32:esp32:PartitionScheme=default"
INDEX_URL="https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json"

if [[ "${SIMPLEOTA_RELEASE:-}" == "true" ]]; then
  "${ROOT}/scripts/secrets.sh" check
elif [[ ! -f "${SKETCH}/secrets.h" ]]; then
  cp "${SKETCH}/secrets.example.h" "${SKETCH}/secrets.h"
fi

if ! arduino-cli config dump 2>/dev/null | grep -Fq "${INDEX_URL}"; then
  arduino-cli config init >/dev/null 2>&1 || true
  arduino-cli config add board_manager.additional_urls "${INDEX_URL}"
fi

arduino-cli core update-index
arduino-cli core install "esp32:esp32@${CORE_VERSION}"
arduino-cli lib install "SimpleOTAClient@${LIB_VERSION}"
arduino-cli compile \
  --fqbn "${FQBN}" \
  --warnings all \
  --build-path "${BUILD}" \
  "${SKETCH}"

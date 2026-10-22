#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKETCH="${ROOT}/simpleOTA-starter-arduino"
BUILD="${ROOT}/build"

CORE_VERSION="3.3.12"
LIB_VERSION="0.6.0"
INDEX_URL="https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json"

fqbn_for() {
  local chip=$1
  local board="esp32:esp32:${chip}:PartitionScheme=default"
  case "${chip}" in
    esp32)
      printf '%s' "${board}"
      ;;
    esp32s2|esp32s3|esp32c3|esp32c6|esp32h2)
      printf '%s' "${board},CDCOnBoot=cdc"
      ;;
    *)
      echo "Unsupported SIMPLEOTA_CHIP '${chip}'. Supported chips: esp32, esp32s2, esp32s3, esp32c3, esp32c6, esp32h2." >&2
      return 1
      ;;
  esac
}

CHIP="${SIMPLEOTA_CHIP:-esp32}"
FQBN="$(fqbn_for "${CHIP}")"
if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  echo "chip=${CHIP}" >> "${GITHUB_OUTPUT}"
fi

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

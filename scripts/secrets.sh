#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKETCH="${ROOT}/simpleOTA-starter-arduino"
EXAMPLE="${SKETCH}/secrets.example.h"
DEST="${SKETCH}/secrets.h"

value_is_placeholder() {
  local value=$1
  local placeholder
  while IFS= read -r placeholder; do
    if [[ -n "${placeholder}" && "${value}" == "${placeholder}" ]]; then
      return 0
    fi
  done < <(sed -n 's/.*= "\(.*\)";/\1/p' "${EXAMPLE}")
  return 1
}

reject_placeholders() {
  local file=$1
  local value
  while IFS= read -r value; do
    if value_is_placeholder "${value}"; then
      echo "secrets.h uses a placeholder value." >&2
      exit 1
    fi
  done < <(sed -n 's/.*= "\(.*\)";/\1/p' "${file}")
}

check_secrets() {
  if [[ ! -f "${DEST}" ]]; then
    echo "Release build is missing secrets.h." >&2
    exit 1
  fi
  reject_placeholders "${DEST}"
}

c_escape() {
  local value=$1
  value=${value//\\/\\\\}
  value=${value//\"/\\\"}
  printf '%s' "${value}"
}

require_secret() {
  local name=$1
  local value=${!name-}
  if [[ -z "${value}" ]]; then
    echo "Missing secret ${name}." >&2
    return 1
  fi
  if [[ "${value}" == *$'\n'* ]]; then
    echo "Secret ${name} contains a newline." >&2
    return 1
  fi
  if value_is_placeholder "${value}"; then
    echo "Secret ${name} is still a placeholder." >&2
    return 1
  fi
}

write_secrets() {
  local missing=0
  local tmp
  require_secret SIMPLEOTA_WIFI_SSID || missing=1
  require_secret SIMPLEOTA_WIFI_PASSWORD || missing=1
  require_secret SIMPLEOTA_DEVICE_TOKEN || missing=1
  if [[ "${missing}" -ne 0 ]]; then
    exit 1
  fi

  tmp="$(mktemp)"
  trap 'rm -f "${tmp}"' EXIT
  {
    printf '%s\n' '#pragma once' ''
    printf 'static const char* WIFI_SSID = "%s";\n' "$(c_escape "${SIMPLEOTA_WIFI_SSID}")"
    printf 'static const char* WIFI_PASS = "%s";\n' "$(c_escape "${SIMPLEOTA_WIFI_PASSWORD}")"
    printf 'static const char* SOTA_TOKEN = "%s";\n' "$(c_escape "${SIMPLEOTA_DEVICE_TOKEN}")"
  } > "${tmp}"
  reject_placeholders "${tmp}"
  mv "${tmp}" "${DEST}"
  trap - EXIT
}

case "${1:-}" in
  write) write_secrets ;;
  check) check_secrets ;;
  *)
    echo "Usage: secrets.sh write|check" >&2
    exit 1
    ;;
esac

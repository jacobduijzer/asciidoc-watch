#!/usr/bin/env bash

set -Eeuo pipefail

DOCS_DIR="${DOCS_DIR:-.}"

SOURCE_DIR="${SOURCE_DIR:-/work}"
OUTPUT_DIR="${OUTPUT_DIR:-${SOURCE_DIR}/output}"

OUTPUT_FILE="${OUTPUT_FILE:-document.pdf}"
POLL_INTERVAL="${POLL_INTERVAL:-1}"
ONCE="${ONCE:-false}"
current_child_pid=""

stop_watcher() {
  echo
  echo "Stopping watcher."

  if [[ -n "${current_child_pid}" ]] && kill -0 "${current_child_pid}" 2>/dev/null; then
    kill "${current_child_pid}" 2>/dev/null || true
    wait "${current_child_pid}" 2>/dev/null || true
  fi

  exit 0
}

trap stop_watcher INT TERM

# Optional environment variables:
#
# INPUT_FILE=index.adoc
# THEME=themes/bimcollab-theme.yml
# ONCE=true

if [[ ! -d "${SOURCE_DIR}" ]]; then
  echo "Source directory does not exist: ${SOURCE_DIR}"
  exit 1
fi

mkdir -p "${OUTPUT_DIR}"

# Resolve relative AsciiDoc paths, such as themes and includes,
# from the mounted documentation directory.
cd "${SOURCE_DIR}"

find_input_file() {
  if [[ -n "${INPUT_FILE:-}" ]]; then
    echo "${INPUT_FILE}"
    return 0
  fi

  if [[ -f "index.adoc" ]]; then
    echo "index.adoc"
    return 0
  fi

  if [[ -f "index.asciidoc" ]]; then
    echo "index.asciidoc"
    return 0
  fi

  local discovered_file

  discovered_file="$(
    find . \
      -maxdepth 1 \
      -type f \
      \( -name "*.adoc" -o -name "*.asciidoc" \) \
      -print |
      sort |
      head -n 1
  )"

  if [[ -n "${discovered_file}" ]]; then
    echo "${discovered_file#./}"
    return 0
  fi

  return 1
}

resolve_theme() {
  if [[ -n "${THEME:-}" ]]; then
    if [[ "${THEME}" = /* ]]; then
      echo "${THEME}"
    else
      echo "${SOURCE_DIR}/${THEME}"
    fi

    return 0
  fi

  if [[ -f "theme.yml" ]]; then
    echo "${SOURCE_DIR}/theme.yml"
    return 0
  fi

  if [[ -f "theme.yaml" ]]; then
    echo "${SOURCE_DIR}/theme.yaml"
    return 0
  fi

  return 1
}

calculate_hash() {
  find "${SOURCE_DIR}" \
    -path "${OUTPUT_DIR}" -prune -o \
    -type f \
    \( \
    -name "*.adoc" \
    -o -name "*.asciidoc" \
    -o -name "*.yml" \
    -o -name "*.yaml" \
    -o -name "*.png" \
    -o -name "*.jpg" \
    -o -name "*.jpeg" \
    -o -name "*.gif" \
    -o -name "*.svg" \
    -o -name "*.webp" \
    -o -name "*.ttf" \
    -o -name "*.otf" \
    \) \
    -print0 |
    sort -z |
    xargs -0 -r sha256sum |
    sha256sum |
    cut -d " " -f 1
}

build_pdf() {
  local input_file
  local input_path
  local theme_path=""
  local args=()
  local started_at

  started_at="$(date '+%Y-%m-%d %H:%M:%S')"

  if ! input_file="$(find_input_file)"; then
    echo "No AsciiDoc input file found in ${SOURCE_DIR}."
    echo "Create index.adoc or set INPUT_FILE."
    return 1
  fi

  if [[ "${input_file}" = /* ]]; then
    input_path="${input_file}"
  else
    input_path="${SOURCE_DIR}/${input_file}"
  fi

  if [[ ! -f "${input_path}" ]]; then
    echo "Input file does not exist: ${input_path}"
    return 1
  fi

  if theme_path="$(resolve_theme)"; then
    if [[ ! -f "${theme_path}" ]]; then
      echo "Theme file does not exist: ${theme_path}"
      return 1
    fi

    args+=(
      -a "pdf-theme=${theme_path}"
    )
  fi

  echo
  echo "=================================================="
  echo "Building PDF at ${started_at}"
  echo "Input : ${input_path}"
  echo "Output: ${OUTPUT_DIR}/${OUTPUT_FILE}"

  if [[ -n "${theme_path}" ]]; then
    echo "Theme : ${theme_path}"
  fi

  echo "=================================================="

  asciidoctor-pdf \
    --failure-level=WARN \
    --trace \
    --base-dir "${SOURCE_DIR}" \
    "${args[@]}" \
    -D "${OUTPUT_DIR}" \
    -o "${OUTPUT_FILE}" \
    "${input_file}" &

  current_child_pid="$!"

  if wait "${current_child_pid}"; then
    current_child_pid=""
    echo "Created ${OUTPUT_DIR}/${OUTPUT_FILE} at $(date '+%Y-%m-%d %H:%M:%S')"
  else
    current_child_pid=""
    echo "PDF build failed at $(date '+%Y-%m-%d %H:%M:%S')."
    return 1
  fi
}

echo "AsciiDoc PDF watcher"
echo "Host source   : ${DOCS_DIR}"
echo "Container src : ${SOURCE_DIR}"
echo "Working dir   : $(pwd)"
echo "Output        : ${OUTPUT_DIR}/${OUTPUT_FILE}"
echo "Poll interval : ${POLL_INTERVAL}s"

if [[ "${ONCE}" == "true" ]]; then
  build_pdf
  exit $?
fi

previous_hash=""

while true; do
  current_hash="$(calculate_hash)"

  if [[ "${current_hash}" != "${previous_hash}" ]]; then
    previous_hash="${current_hash}"

    if ! build_pdf; then
      echo "Build failed. Waiting for the next change..."
    fi
  fi

  sleep "${POLL_INTERVAL}" &
  current_child_pid="$!"
  wait "${current_child_pid}" || true
  current_child_pid=""
done

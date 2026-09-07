#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_SKILLS_DIR="${SCRIPT_DIR}/skills"

if [[ ! -d "${SOURCE_SKILLS_DIR}" ]]; then
  echo "Error: Source skills directory '${SOURCE_SKILLS_DIR}' not found." >&2
  exit 1
fi

if [[ $# -lt 1 || -z "${1:-}" ]]; then
  echo "Usage: $0 <destination-directory>" >&2
  exit 1
fi

TARGET_DIR="${1/#\~/$HOME}"

mkdir -p "${TARGET_DIR}"

echo "Installing skills from '${SOURCE_SKILLS_DIR}' to '${TARGET_DIR}'..."

# Copy each skill directory to the target location
for skill_path in "${SOURCE_SKILLS_DIR}"/*; do
  if [[ -d "${skill_path}" ]]; then
    skill_name="$(basename "${skill_path}")"
    echo "  -> Copying ${skill_name}..."
    cp -r "${skill_path}" "${TARGET_DIR}/"
  fi
done

echo "Successfully installed skills to '${TARGET_DIR}'."

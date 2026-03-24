#!/usr/bin/env bash

set -uo pipefail

print_help() {
  cat <<'EOF'
Usage: pacman-info.sh <command-or-path> [command-or-path...]

Query installed package information by command name or owned file path.
EOF
}

resolve_package_name() {
  local target
  local query_output

  target="$(command -v "$1")" || return 1
  query_output=$(paru -Qo -- "$target") || return 1
  awk 'END { print $(NF - 2) }' <<<"$query_output"
}

main() {
  local status=0
  local package_name
  local target
  local -a packages=()

  if [ "$#" -eq 0 ]; then
    print_help
    return 0
  fi

  for target in "$@"; do
    package_name=$(resolve_package_name "$target") || {
      status=1
      continue
    }
    packages+=("$package_name")
  done

  if [ "${#packages[@]}" -gt 0 ]; then
    paru -Qi -- "${packages[@]}" | bat || status=1
  fi

  return "$status"
}

main "$@"

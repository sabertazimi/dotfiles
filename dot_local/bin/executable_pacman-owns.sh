#!/usr/bin/env bash

set -uo pipefail

print_help() {
  cat <<'EOF'
Usage: pacman-info.sh <package-or-path> [package-or-path...]

Query installed package information by package name or owned file path.
Arguments containing `/` are treated as paths and resolved via `paru -Qo`;
other arguments are treated as package names and queried via `paru -Qi`.
EOF
}

resolve_package_name() {
  local target="$1"
  local query_output

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
    if [[ "$target" == */* ]]; then
      package_name=$(resolve_package_name "$target") || {
        status=1
        continue
      }
      packages+=("$package_name")
      continue
    fi

    packages+=("$target")
  done

  if [ "${#packages[@]}" -gt 0 ]; then
    paru -Qi -- "${packages[@]}" | bat || status=1
  fi

  return "$status"
}

main "$@"

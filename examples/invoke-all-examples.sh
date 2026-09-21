#!/usr/bin/env sh
# Run every public read-only request example and report the HTTP outcome.
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
api_base='https://aggre.orbbit.ai'
timeout_seconds=180

usage() {
    printf '%s\n' 'Usage: sh examples/invoke-all-examples.sh [--api-base URL] [--timeout SECONDS]'
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        -b|--api-base)
            api_base=${2:?missing API base URL}
            shift 2
            ;;
        -t|--timeout)
            timeout_seconds=${2:?missing timeout seconds}
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            usage >&2
            exit 2
            ;;
    esac
done

: "${AGGRE_API_KEY:?Set AGGRE_API_KEY before running this script.}"

passed=0
failed=0
for request_file in "$script_dir"/requests/*.json; do
    request_name=$(basename "$request_file")
    response_file=$(mktemp)
    if "$script_dir/fetch-aggre.sh" --request "$request_file" --api-base "$api_base" --timeout "$timeout_seconds" >"$response_file" 2>&1; then
        printf 'PASS  %s\n' "$request_name"
        passed=$((passed + 1))
    else
        printf 'FAIL  %s\n' "$request_name" >&2
        sed -n '1,4p' "$response_file" >&2
        failed=$((failed + 1))
    fi
    rm -f "$response_file"
done

printf 'Summary: %s passed, %s failed\n' "$passed" "$failed"
[ "$failed" -eq 0 ]

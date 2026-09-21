#!/usr/bin/env sh
# Send one JSON request file to Aggre's REST MCP endpoint.
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
request_file="$script_dir/requests/01-retrieve-labor-notice.json"
api_base='https://aggre.orbbit.ai'
timeout_seconds=180

usage() {
    printf '%s\n' 'Usage: sh examples/fetch-aggre.sh [--request FILE] [--api-base URL] [--timeout SECONDS]'
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        -r|--request)
            request_file=${2:?missing request file}
            shift 2
            ;;
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

: "${AGGRE_API_KEY:?Set AGGRE_API_KEY before running this script. It is intentionally never read from a file.}"

if [ ! -r "$request_file" ]; then
    printf 'Request file was not found or is unreadable: %s\n' "$request_file" >&2
    exit 2
fi

response_file=$(mktemp)
trap 'rm -f "$response_file"' EXIT HUP INT TERM
api_base=${api_base%/}

http_status=$(curl --silent --show-error \
    --output "$response_file" \
    --write-out '%{http_code}' \
    --max-time "$timeout_seconds" \
    --request POST "$api_base/v1/mcp/call" \
    --header "Authorization: Bearer $AGGRE_API_KEY" \
    --header 'Content-Type: application/json' \
    --header 'Accept: application/json' \
    --header 'User-Agent: aggre-doc-example/1.0' \
    --data-binary "@$request_file")

case "$http_status" in
    2??)
        cat "$response_file"
        ;;
    *)
        printf 'Aggre API returned HTTP %s\n' "$http_status" >&2
        cat "$response_file" >&2
        exit 1
        ;;
esac

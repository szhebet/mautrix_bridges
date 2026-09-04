#!/bin/sh
# rebuild.sh — rebuilds the mautrix-telegram container image from local sources.
#
# Usage:
#   ./rebuild.sh [--no-cache] [--tag <name>] [--push]
#
# Options:
#   --no-cache   Do not use Docker layer caching.
#   --tag NAME   Override the image name/tag (default: mautrix-telegram:latest).
#   --push       Push the image to a registry after building.
#   -h, --help   Show this help.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
IMAGE="mautrix-telegram:latest"
EXTRA_ARGS=""
PUSH=0

for arg in "$@"; do
	case "$arg" in
		-h|--help)
			grep '^#' "$0" | sed 's/^# \{0,1\}//'
			exit 0
			;;
		--no-cache)
			EXTRA_ARGS="$EXTRA_ARGS --no-cache"
			;;
		--push)
			PUSH=1
			;;
		--tag)
			echo "Error: --tag requires a value" >&2
			exit 1
			;;
		--tag=*)
			IMAGE="${arg#*=}"
			;;
		*)
			echo "Unknown argument: $arg" >&2
			exit 1
			;;
	esac
done

if ! command -v docker >/dev/null 2>&1; then
	echo "Error: docker is not installed or not in PATH." >&2
	exit 1
fi

echo ">> Building $IMAGE"
# shellcheck disable=SC2086
docker build $EXTRA_ARGS -t "$IMAGE" "$SCRIPT_DIR"

if [ "$PUSH" = "1" ]; then
	echo ">> Pushing $IMAGE"
	docker push "$IMAGE"
fi

echo ">> Done: $IMAGE"

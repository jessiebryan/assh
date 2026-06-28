#!/usr/bin/env bash
#
# build.sh - Build the `assh` binary locally (does not install).
#
# Usage:
#   ./build.sh              # build ./assh for the host platform
#   ./build.sh -o /tmp/assh # build to a custom output path
#   ./build.sh --no-gen     # skip `go generate` (shell completions)
#   GOOS=linux GOARCH=arm64 ./build.sh   # cross-compile
#
set -euo pipefail

# Move to the repo root (directory containing this script).
cd "$(dirname "$0")"

OUTPUT="assh"
RUN_GENERATE=1

while [[ $# -gt 0 ]]; do
	case "$1" in
		-o|--output)
			OUTPUT="$2"
			shift 2
			;;
		--no-gen)
			RUN_GENERATE=0
			shift
			;;
		-h|--help)
			grep '^#' "$0" | sed 's/^# \{0,1\}//'
			exit 0
			;;
		*)
			echo "unknown argument: $1" >&2
			exit 1
			;;
	esac
done

# Version metadata stamped into pkg/version via -ldflags.
VERSION="$(git describe --tags --always 2>/dev/null || echo dev)"
VCS_REF="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"

export CGO_ENABLED=0

if [[ "$RUN_GENERATE" -eq 1 ]]; then
	echo ">> go generate (regenerating shell completions)"
	go generate
fi

echo ">> building ${OUTPUT} (version=${VERSION} ref=${VCS_REF})"
go build -trimpath \
	-ldflags="-s -w \
		-X 'moul.io/assh/v2/pkg/version.Version=${VERSION}' \
		-X 'moul.io/assh/v2/pkg/version.VcsRef=${VCS_REF}'" \
	-o "${OUTPUT}" .

echo ">> done: $(pwd)/${OUTPUT}"
echo "   install manually, e.g.: mv ${OUTPUT} /usr/local/bin/assh"

#!/usr/bin/env bash
#
# rpi-imager-no-root build helper
#
# Clones the upstream rpi-imager tree, applies the no-root patches and
# builds with CMake. Intended for macOS/Linux development machines that
# have the rpi-imager build dependencies installed.
#
# Usage:
#   ./build.sh                 # build with the Linux patch (default, tested)
#   ./build.sh --windows       # build with the Windows patch (experimental)
#
# Binary output lands in ./_build/src/rpi-imager.

set -euo pipefail

UPSTREAM_URL="${UPSTREAM_URL:-https://github.com/raspberrypi/rpi-imager.git}"
REF="${REF:-main}"
WORK_TREE="/tmp/rpi-imager-no-root-src"

MODE="linux"
if [[ "${1:-}" == "--windows" ]]; then
  MODE="windows"
fi

PATCH="patches/0001-linux-allow-running-without-root.patch"
if [[ "$MODE" == "windows" ]]; then
  PATCH="patches/0002-windows-allow-running-without-admin.patch"
fi

echo "==> fetching upstream rpi-imager @ ${REF}"
rm -rf "$WORK_TREE"
git clone --quiet --filter=blob:none --branch "$REF" "$UPSTREAM_URL" "$WORK_TREE"

echo "==> applying ${PATCH}"
git -C "$WORK_TREE" apply --check "$PATCH"
git -C "$WORK_TREE" apply "$PATCH"

echo "==> configuring cmake (${MODE})"
cmake \
  -S "$WORK_TREE/src" \
  -B "$WORK_TREE/_build" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="/usr/local"

echo "==> building"
cmake --build "$WORK_TREE/_build" --parallel

echo
echo "Done. Run with:  $WORK_TREE/_build/src/rpi-imager"
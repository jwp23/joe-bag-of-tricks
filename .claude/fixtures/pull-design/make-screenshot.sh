#!/usr/bin/env bash
# Renders a fixture's index.html to screenshot.png so the pull-design runs have an image artifact to read.
set -euo pipefail
dir="${1:?fixture dir}"
npx --yes playwright screenshot --viewport-size=1280,800 "file://$(cd "$dir" && pwd)/index.html" "$dir/screenshot.png"
echo "wrote $dir/screenshot.png"

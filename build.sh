#!/usr/bin/env bash
# Build the combined Glove80 firmware locally with Nix (same as CI).
# Output: ./glove80.uf2 -- flash this one file to both halves.
set -euo pipefail
cd "$(dirname "$0")"

# MoErgo's ZMK fork, tracked on main like the CI workflow.
if [ -d src/.git ]; then
  git -C src pull --ff-only -q
else
  git clone -q --depth 1 https://github.com/moergo-sc/zmk.git src
fi

nix-build config -o result
cp -f result/glove80.uf2 glove80.uf2
echo "Built: $(pwd)/glove80.uf2"

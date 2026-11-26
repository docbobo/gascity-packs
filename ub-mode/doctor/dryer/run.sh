#!/bin/sh
# Install unclebob/dryer (duplication gate) under ~/.gc/cache/ub-mode and link ~/.gc/cache/bin/dryer.
dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
exec "$dir/../../assets/scripts/install-ub-tool.sh" "dryer" "https://github.com/unclebob/dryer" "ad371d460854b937039410d2c3889a4da94a753a"

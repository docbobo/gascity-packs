#!/bin/sh
# Install unclebob/crapper (CRAP score gate) under ~/.gc/cache/ub-mode and link ~/.gc/cache/bin/crapper.
dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
exec "$dir/../../assets/scripts/install-ub-tool.sh" "crapper" "https://github.com/unclebob/crapper" "fdd0c01387e4211c74b23c2cdd11c06d90883838"

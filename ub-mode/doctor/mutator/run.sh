#!/bin/sh
# Install unclebob/mutator (mutation coverage gate) under ~/.gc/cache/ub-mode and link ~/.gc/cache/bin/mutator.
dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
exec "$dir/../../assets/scripts/install-ub-tool.sh" "mutator" "https://github.com/unclebob/mutator" "264dc965fa79b60942018143e7e323b517635a69"

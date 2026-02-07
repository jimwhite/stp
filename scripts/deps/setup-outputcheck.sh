#!/usr/bin/env bash

# OutputCheck is a submodule, no build needed
# Just verify it exists
if [ -d "deps/OutputCheck" ]; then
    echo "OutputCheck submodule present"
else
    echo "ERROR: OutputCheck submodule not found. Run: git submodule update --init"
    exit 1
fi

# EOF

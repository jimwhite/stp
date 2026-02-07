#!/usr/bin/env bash

set -e -u -o pipefail

dep_dir="deps"
install_dir=$(readlink -fm "${dep_dir}"/install)

[ ! -d "${install_dir}" ] && mkdir -p "${install_dir}"

cd "${dep_dir}/gtest"
mkdir -p build && cd build
cmake -DCMAKE_INSTALL_PREFIX:PATH="${install_dir}" ..
cmake --build . --parallel
cmake --install .

# EOF

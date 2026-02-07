#!/usr/bin/env bash

set -e -u -o pipefail

dep_dir="deps"
install_dir=$(readlink -fm "${dep_dir}"/install)

[ ! -d "${install_dir}" ] && mkdir -p "${install_dir}"

cd "${dep_dir}/minisat"
mkdir -p build && cd build
cmake -DCMAKE_INSTALL_PREFIX:PATH="${install_dir}" -DBUILD_SHARED_LIBS=OFF ..
cmake --build . --parallel
cmake --install .

# EOF

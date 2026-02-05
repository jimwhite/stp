#!/usr/bin/env bash

set -e -u -o pipefail

dep_dir="deps"
install_dir=$(readlink -fm "${dep_dir}"/install)

[ ! -d "${install_dir}" ] && mkdir -p "${install_dir}"

echo "Setting up CMS in ${install_dir}"

dep="cms"

cd "${dep_dir}"

# Install cadical/cadiback first as siblings of cms (required by CMS find_library)
git clone https://github.com/meelgroup/cadical
cd cadical
git checkout -d 16dde5487287b349d19eb9f16642a797e38ca34f
CXXFLAGS="-fPIC" ./configure
make -j"$(nproc)"
cd ..

git clone https://github.com/meelgroup/cadiback
cd cadiback
git checkout mccomp2024
CXXFLAGS="-fPIC" ./configure
make -j"$(nproc)"
cd ..

git clone https://github.com/msoos/cryptominisat "${dep}"
cd "${dep}"
git checkout -d release/5.13.0
mkdir build && cd build
cmake -DENABLE_ASSERTIONS=OFF \
      -DCMAKE_INSTALL_PREFIX:PATH="${install_dir}" \
      -DSTATICCOMPILE=ON \
      ..
cmake --build . --parallel "$(nproc)"
cmake --install .
cd ..

# EOF

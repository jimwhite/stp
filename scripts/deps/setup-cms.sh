#!/usr/bin/env bash

set -e -u -o pipefail

dep_dir="deps"
install_dir=$(readlink -fm "${dep_dir}"/install)

[ ! -d "${install_dir}" ] && mkdir -p "${install_dir}"

echo "Setting up CMS in ${install_dir}"

cd "${dep_dir}"

# Build cadical (submodule already at correct commit)
cd cadical
CXXFLAGS="-fPIC" ./configure
make -j"$(nproc)"
cd ..

# Build cadiback (submodule already at correct branch)
cd cadiback
# Create config.hpp manually since generate script needs .git directory
cat > config.hpp << 'EOF'
#define VERSION "1.0"
#define GITID "submodule"
#define BUILD ""
EOF
CXXFLAGS="-fPIC" ./configure
touch config.hpp  # Prevent make from regenerating
make -j"$(nproc)"
cd ..

# Build cryptominisat (submodule already at correct tag)
cd cryptominisat
mkdir -p build && cd build
cmake -DENABLE_ASSERTIONS=OFF \
      -DCMAKE_INSTALL_PREFIX:PATH="${install_dir}" \
      -DSTATICCOMPILE=ON \
      ..
cmake --build . --parallel
cmake --install .
cd ..

# EOF

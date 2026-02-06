# This Dockerfile builds a statically-compiled instance of STP with MiniSat and
# CryptoMiniSat that evaluates SMTLIB2 inputs provided on standard input:
#
#     docker build --tag stp/stp .
#     cat example.smt2 | docker run --rm -i stp/stp


FROM ubuntu:22.04 AS builder

# Install dependencies
RUN apt-get update \
       && apt-get install --no-install-recommends -y \
       bison \
       ca-certificates \
       cmake \
       flex \
       g++ \
       gcc \
       git \
       libboost-program-options-dev \
       libgmp-dev \
       libm4ri-dev \
       libtinfo-dev \
       make \
       pkg-config \
       wget \
       zlib1g-dev \
       && rm -rf /var/lib/apt/lists/*

COPY . /stp
WORKDIR /stp

# Build dependencies from submodules
RUN make -f deps/Makefile all

# Remove ABC's cadical and eslim modules to avoid symbol conflicts with deps/cadical.
# ABC bundles a modified cadical 2.2.0 internally; eslim depends on that internal API.
# See DEPENDENCIES.md for full explanation of the architecture.
RUN sed -i 's|src/sat/cadical ||; s|src/opt/eslim ||' lib/extlib-abc/Makefile

# Build STP
RUN mkdir build \
       && cd build \
       && cmake .. \
       -DCMAKE_BUILD_TYPE=Release \
       -DENABLE_ASSERTIONS=OFF \
       -DSTATICCOMPILE=ON \
       && cmake --build . \
       && cmake --install .

# Run STP tests
RUN cd build && ctest --output-on-failure

# # Set up to run in a minimal container
FROM scratch
COPY --from=builder /usr/local/bin/stp /stp
ENTRYPOINT ["/stp", "--SMTLIB2"]

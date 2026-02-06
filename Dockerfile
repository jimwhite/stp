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

# Remove ABC's bundled cadical to avoid duplicate symbols with CryptoMiniSat's cadical
RUN sed -i 's| src/sat/cadical||' lib/extlib-abc/Makefile

RUN ./scripts/deps/setup-gtest.sh \
       && ./scripts/deps/setup-outputcheck.sh \
       && ./scripts/deps/setup-cms.sh \
       && ./scripts/deps/setup-minisat.sh

RUN mkdir build \
       && cd build \
       && cmake .. \
       -DCMAKE_BUILD_TYPE=Release \
       -DENABLE_ASSERTIONS=OFF \
       -DSTATICCOMPILE=ON \
       && cmake --build . \
       && cmake --install .

# # Set up to run in a minimal container
FROM scratch
COPY --from=builder /usr/local/bin/stp /stp
ENTRYPOINT ["/stp", "--SMTLIB2"]

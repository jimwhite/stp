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
RUN ./scripts/deps/setup-gtest.sh
RUN ./scripts/deps/setup-outputcheck.sh
RUN ./scripts/deps/setup-cms.sh
RUN ./scripts/deps/setup-minisat.sh

RUN mkdir build
WORKDIR /stp/build

RUN cmake .. -DSTATICCOMPILE=ON \
  && cmake --build . --parallel \
  && cmake --install .

# Set up to run in a minimal container
FROM scratch
COPY --from=builder /usr/local/bin/stp /stp
ENTRYPOINT ["/stp", "--SMTLIB2"]

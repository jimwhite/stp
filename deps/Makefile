# Makefile for building STP dependencies (submodules in deps/)
#
# Usage:
#   make -f deps/Makefile all        # Build all dependencies
#   make -f deps/Makefile cadical    # Build just cadical
#   make -f deps/Makefile clean      # Clean all builds
#
# Dependencies should be added as submodules:
#   git submodule add https://github.com/meelgroup/cadical deps/cadical
#   git submodule add https://github.com/meelgroup/cadiback deps/cadiback
#   git submodule add https://github.com/msoos/cryptominisat deps/cryptominisat
#   git submodule add https://github.com/stp/minisat deps/minisat
#   git submodule add https://github.com/stp/googletest deps/gtest
#   git submodule add https://github.com/stp/OutputCheck deps/OutputCheck

NPROC := $(shell nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
DEPS_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
INSTALL_DIR := $(DEPS_DIR)install

.PHONY: all clean cadical cadiback cryptominisat minisat gtest outputcheck

all: cadical cadiback cryptominisat minisat gtest outputcheck

# CaDiCaL SAT solver (needed by cadiback and cryptominisat)
cadical: $(DEPS_DIR)cadical/build/libcadical.a

$(DEPS_DIR)cadical/build/libcadical.a:
	cd $(DEPS_DIR)cadical && \
	CXXFLAGS="-fPIC" ./configure && \
	make -j$(NPROC)

# Cadiback (depends on cadical)
cadiback: cadical $(DEPS_DIR)cadiback/libcadiback.a

$(DEPS_DIR)cadiback/libcadiback.a:
	cd $(DEPS_DIR)cadiback && \
	echo '#define VERSION "1.0"' > config.hpp && \
	echo '#define GITID "submodule"' >> config.hpp && \
	echo '#define BUILD ""' >> config.hpp && \
	CXXFLAGS="-fPIC" ./configure && \
	touch config.hpp && \
	make -j$(NPROC)

# CryptoMiniSat (depends on cadical, cadiback)
cryptominisat: cadical cadiback $(DEPS_DIR)cryptominisat/build/lib/libcryptominisat5.a

$(DEPS_DIR)cryptominisat/build/lib/libcryptominisat5.a:
	mkdir -p $(DEPS_DIR)cryptominisat/build && \
	cd $(DEPS_DIR)cryptominisat/build && \
	cmake .. \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_INSTALL_PREFIX=$(INSTALL_DIR) \
		-DENABLE_ASSERTIONS=OFF \
		-DSTATICCOMPILE=ON && \
	cmake --build . --parallel $(NPROC) && \
	cmake --install .

# MiniSat
minisat: $(DEPS_DIR)minisat/build/libminisat.a

$(DEPS_DIR)minisat/build/libminisat.a:
	mkdir -p $(DEPS_DIR)minisat/build && \
	cd $(DEPS_DIR)minisat/build && \
	cmake .. \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_INSTALL_PREFIX=$(INSTALL_DIR) \
		-DBUILD_SHARED_LIBS=OFF && \
	cmake --build . --parallel $(NPROC) && \
	cmake --install .

# Google Test
gtest: $(DEPS_DIR)gtest/build/lib/libgtest.a

$(DEPS_DIR)gtest/build/lib/libgtest.a:
	mkdir -p $(DEPS_DIR)gtest/build && \
	cd $(DEPS_DIR)gtest/build && \
	cmake .. \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_INSTALL_PREFIX=$(INSTALL_DIR) && \
	cmake --build . --parallel $(NPROC) && \
	cmake --install .

# OutputCheck (Python, no build needed)
outputcheck:
	@test -d $(DEPS_DIR)OutputCheck && echo "OutputCheck ready" || echo "OutputCheck submodule not found"

# Test targets
.PHONY: test test-cadical test-cryptominisat test-minisat test-gtest

test: test-cadical test-cryptominisat test-minisat

test-cadical:
	cd $(DEPS_DIR)cadical && make test

test-cryptominisat:
	cd $(DEPS_DIR)cryptominisat/build && ctest --output-on-failure

test-minisat:
	@echo "MiniSat has no test suite"

test-gtest:
	cd $(DEPS_DIR)gtest/build && ctest --output-on-failure

clean:
	-rm -rf $(DEPS_DIR)cadical/build
	-cd $(DEPS_DIR)cadical && make clean 2>/dev/null || true
	-cd $(DEPS_DIR)cadiback && make clean 2>/dev/null || true
	-rm -rf $(DEPS_DIR)cryptominisat/build
	-rm -rf $(DEPS_DIR)minisat/build
	-rm -rf $(DEPS_DIR)gtest/build
	-rm -rf $(INSTALL_DIR)

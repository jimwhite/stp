# STP Dependency Architecture

This document explains the dependency relationships in STP and the build strategy for maintaining a current, reliable SMT solver.

## Project Overview

**STP** (Simple Theorem Prover) is an SMT solver for bitvectors and arrays. It uses multiple SAT solvers as backends and integrates ABC for logic synthesis optimizations.

- **Repository**: [stp/stp](https://github.com/stp/stp)
- **Latest Release**: v2.3.4 (June 2024)
- **Maintainers**: @msoos (Mate Soos), @delcypher, @thomaslhunter

## Dependency Tree

```
STP
├── lib/extlib-abc          → berkeley-abc/abc (logic synthesis)
│   └── src/sat/cadical     → BUNDLED cadical 2.2.0 (modified, internal)
│   └── src/opt/eslim       → depends on ABC's internal cadical
│
├── deps/cadical            → meelgroup/cadical (fork of arminbiere/cadical)
├── deps/cadiback           → meelgroup/cadiback (backbone extractor)
│   └── requires ../cadical → expects meelgroup/cadical at sibling path
├── deps/cryptominisat      → msoos/cryptominisat
│   └── optionally uses cadical/cadiback
├── deps/minisat            → stp/minisat (fork)
├── deps/gtest              → Google Test
└── deps/OutputCheck        → test output validation
```

## CaDiCaL Fork Situation

There are **two relevant CaDiCaL forks**:

### 1. Upstream: arminbiere/cadical
- **Repository**: [arminbiere/cadical](https://github.com/arminbiere/cadical)
- **Latest Version**: v3.0.0 (2.6k stars, 34 releases)
- **Status**: Actively maintained by original author
- **API**: Standard ccadical.h interface

### 2. Meelgroup Fork: meelgroup/cadical
- **Repository**: [meelgroup/cadical](https://github.com/meelgroup/cadical)
- **Version**: ~2.1.x (no releases, forked from upstream)
- **Status**: Modified for CryptoMiniSat/Cadiback integration
- **Used by**: deps/cadical in STP

### Key Difference
The meelgroup fork adds features needed by CryptoMiniSat and Cadiback but lags behind upstream versions. It's functional but not actively releasing.

## ABC's Bundled CaDiCaL Problem

**ABC bundles a complete, modified copy of CaDiCaL 2.2.0** in `src/sat/cadical/`. This is a deliberate design choice - ABC embeds all SAT solvers internally for self-containment.

### Files in ABC's cadical (~80 source files)
- Full CaDiCaL source (all .cpp files)
- `cadicalSolver.c` - ABC's C wrapper
- `cadical_ccadical.cpp` - C API implementation with ABC-specific modifications
- `cadical_kitten.c` - embedded SMT solver

### ABC's Modifications
ABC's ccadical wrapper expects methods **not in upstream cadical**:
- `ccadical_resize()` - preallocate variables
- `ccadical_clauses()` - clause count
- `ccadical_conflicts()` - conflict count

### The Conflict
When building STP:
1. ABC compiles its bundled cadical → produces symbols like `ccadical_init`, `kitten_*`
2. deps/cadical compiles separately → produces same symbols
3. **Linker error**: duplicate symbol definitions

Additionally, ABC's `eslim` module (in `src/opt/eslim/`) depends on ABC's internal cadical API, not the standard ccadical.h interface.

## Build Strategy: Option A (Implemented)

**Disable ABC's cadical and eslim modules entirely.**

### Rationale
1. **eslim** is an optional optimization module - STP functions without it
2. ABC's other SAT solvers (glucose, kissat, etc.) remain available
3. Eliminates symbol conflicts completely
4. Keeps all projects at their current/upstream versions
5. Simplest solution with minimal maintenance burden

### Implementation
```dockerfile
# In Dockerfile:
RUN sed -i 's|src/sat/cadical ||; s|src/opt/eslim ||' lib/extlib-abc/Makefile
```

This removes both modules from ABC's build without modifying any source files.

## Alternative Approaches (Not Implemented)

### Option B: Use Only ABC's CaDiCaL
- Make deps/cadical, cadiback, cryptominisat use ABC's bundled version
- **Problem**: ABC's cadical is modified with non-standard API; cadiback expects specific directory structure

### Option C: Maintain STP Fork of ABC
- Fork ABC, modify to use external cadical
- **Problem**: High maintenance burden, ABC has no releases

### Option D: Wrapper/Namespace Approach
- Rename symbols in one cadical to avoid conflicts
- **Problem**: Complex, error-prone, requires ongoing maintenance

## Testing Strategy

### STP Tests
```bash
cd build && ctest --output-on-failure
```

### CryptoMiniSat Tests
```bash
cd deps/cryptominisat/build && ctest
```

### CaDiCaL Tests
```bash
cd deps/cadical && make test
```

### Cadiback Tests
```bash
cd deps/cadiback && make test
```

### ABC Tests
ABC has limited formal tests but includes:
```bash
cd lib/extlib-abc && make test  # if available
```

### Full Test Suite
The Dockerfile should be extended to run all tests during build to catch regressions.

## Version Tracking

| Component | Current | Upstream | Notes |
|-----------|---------|----------|-------|
| STP | v2.3.4 | v2.3.4 | Latest |
| CaDiCaL (deps) | ~2.1.x | v3.0.0 (arminbiere) | meelgroup fork |
| CryptoMiniSat | v5.13.0 | v5.13.0 | Latest |
| Cadiback | main | main | No releases |
| MiniSat | stp fork | stp fork | Maintained |
| ABC | main | main | No releases |

## Maintenance Notes

1. **ABC updates**: When updating ABC submodule, verify eslim/cadical modules are still excluded
2. **CaDiCaL updates**: meelgroup fork may need manual merging from upstream
3. **Test regularly**: Run full test suite after any dependency update
4. **Static build**: Current Dockerfile produces static binary for deployment

## References

- [STP PR #496](https://github.com/stp/stp/pull/496) - ABC submodule addition (discusses cadical issues)
- [ABC Integration Notes](https://github.com/berkeley-abc/abc) - ABC architecture
- [CaDiCaL README](https://github.com/arminbiere/cadical) - Upstream documentation

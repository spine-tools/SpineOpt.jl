# SpineOpt.jl Changes Report (2023-2026)

This report summarizes the most relevant changes to the SpineOpt.jl repository from January 2023 through January 2026, classified into three categories.

## 1. Structural Changes

Major architectural changes, new features, and model enhancements:

1. **Multi-stage optimization framework** - Core infrastructure for hierarchical multi-stage optimization  
   [PR #938](https://github.com/spine-tools/SpineOpt.jl/pull/938)

2. **New HSJ and Fuzzy MGA functionality** - Adaptive Model Generator for Alternative scenarios  
   [PR #1249](https://github.com/spine-tools/SpineOpt.jl/pull/1249)

3. **Multi-year investment economic parameters** - New parameters for economic representation in investments  
   [PR #929](https://github.com/spine-tools/SpineOpt.jl/pull/929)

4. **Piecewise linear efficiency via ratio unit flow** - Enables non-linear efficiency curves  
   [PR #1076](https://github.com/spine-tools/SpineOpt.jl/pull/1076)

5. **Monte Carlo algorithm and blended representative periods** - Stochastic sampling methods  
   [Commit 5787a13](https://github.com/spine-tools/SpineOpt.jl/commit/5787a1345a183fc23585b1305c6c42641a22ca0c)

6. **Minimum node state constraint** - New constraint for storage state lower bounds  
   [PR #1204](https://github.com/spine-tools/SpineOpt.jl/pull/1204)

7. **Minimum connection flow constraint** - New lower bound on connection flows  
   [PR #1208](https://github.com/spine-tools/SpineOpt.jl/pull/1208)

8. **Units out of service variable and constraints** - Tracking outages in optimization  
   [PR #917](https://github.com/spine-tools/SpineOpt.jl/pull/917)

9. **New ramp constraints redesign** - Simplified and corrected ramping formulation  
   [PR #789](https://github.com/spine-tools/SpineOpt.jl/pull/789)

10. **Stage__output relationship** - Simplified fixing outputs across stages  
    [PR #1094](https://github.com/spine-tools/SpineOpt.jl/pull/1094)

## 2. Speed and Memory Improvements

Performance optimizations that improve model building and solving times:

1. **Up to 7x faster _save_outputs!()** - Major improvement in results saving  
   [PR #1217](https://github.com/spine-tools/SpineOpt.jl/pull/1217)

2. **Multi-threaded constraint building and variable bounds** - Parallel model construction  
   [PR #997](https://github.com/spine-tools/SpineOpt.jl/pull/997)

3. **Parallel results saving** - Concurrent output writing per index  
   [PR #1080](https://github.com/spine-tools/SpineOpt.jl/pull/1080)

4. **Options to improve model creation speed** - JuMP optimization flags  
   [PR #1149](https://github.com/spine-tools/SpineOpt.jl/pull/1149)

5. **Iterators for variable/constraint indices** - Reduced memory allocations  
   [PR #982](https://github.com/spine-tools/SpineOpt.jl/pull/982)

6. **Use variable bounds instead of constraints** - Lighter model formulations  
   [PR #986](https://github.com/spine-tools/SpineOpt.jl/pull/986)

7. **Optimized stochastic index generation** - Faster deterministic model setup  
   [PR #992](https://github.com/spine-tools/SpineOpt.jl/pull/992)

8. **Optimized t_lowest_resolution_paths!** - Faster temporal resolution handling  
   [PR #990](https://github.com/spine-tools/SpineOpt.jl/pull/990)

9. **Various performance improvements from v0.7** - Collection of optimizations  
   [PR #1081](https://github.com/spine-tools/SpineOpt.jl/pull/1081)

10. **Skip auto-update structure when not needed** - Faster non-rolling models  
    [PR #981](https://github.com/spine-tools/SpineOpt.jl/pull/981)

## 3. Documentation

Documentation improvements, tutorials, and guides:

1. **Documentation overhaul part 1** - Major restructuring of documentation  
   [PR #1045](https://github.com/spine-tools/SpineOpt.jl/pull/1045)

2. **Stochastic tutorial** - Tutorial on stochastic optimization  
   [PR #1047](https://github.com/spine-tools/SpineOpt.jl/pull/1047)

3. **Multi-year investment tutorial** - Guide for investment optimization  
   [PR #1048](https://github.com/spine-tools/SpineOpt.jl/pull/1048)

4. **Capacity planning tutorial** - Investment planning examples  
   [PR #1049](https://github.com/spine-tools/SpineOpt.jl/pull/1049)

5. **Multi-year tutorial in documentation** - Advanced investment concepts  
   [PR #1078](https://github.com/spine-tools/SpineOpt.jl/pull/1078)

6. **Unit commitment tutorial** - Tutorial for UC modeling  
   [PR #770](https://github.com/spine-tools/SpineOpt.jl/pull/770)

7. **Reserve tutorial and figures** - Guide for reserve modeling  
   [PR #778](https://github.com/spine-tools/SpineOpt.jl/pull/778)

8. **Ramping constraints tutorial** - Tutorial on ramping features  
   [PR #784](https://github.com/spine-tools/SpineOpt.jl/pull/784)

9. **Gallery section in documentation** - New section for showcases  
   [PR #1125](https://github.com/spine-tools/SpineOpt.jl/pull/1125)

10. **Simple system tutorial updates** - Updated for Spine Toolbox 0.8  
    [PR #1151](https://github.com/spine-tools/SpineOpt.jl/pull/1151)

---

## Repository Statistics (January 2023 - January 2026)

| Metric | Count |
|--------|-------|
| **Pull Requests Merged** | 311 |
| **Individual Commits** | 1,632 |
| **Time Period** | 3 years |

### Breakdown by Category (Estimated):
- **Structural Changes**: ~120 PRs (features, constraints, variables)
- **Performance/Bug Fixes**: ~90 PRs (optimizations, fixes)
- **Documentation**: ~50 PRs (tutorials, guides, docstrings)
- **Maintenance/Compat**: ~51 PRs (dependencies, CI, merges)

### Major Releases in This Period:
- v0.9.0 (October 2024)
- v0.9.1 (November 2024)
- v0.10.1 (March 2025)
- v0.11.0 (October 2025)

---

*Report generated on 2026-01-28*

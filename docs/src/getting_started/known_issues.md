# [Known issues](@id known_issues)

This section lists some known issues with SpineOpt.jl and possible workarounds.

## Issue 1: Incompatible Julia version

**Status:** Identified Bug  
**Affects:** SpineOpt.jl is not compatible with Julia 1.12  
**Issue ID:** [#1274](https://github.com/spine-tools/SpineOpt.jl/issues/1274)

### Description

SpineOpt.jl requires Julia versions between 1.10.10 - 1.11. If you encounter compatibility issues, please ensure that you are using a supported Julia version. You can check your Julia version by running `julia --version` in your terminal.

## Issue 2: Investment Variable Reporting with Mixed Temporal Block Configurations

**Status:** Identified Bug  
**Affects:** SpineOpt.jl investment optimization with flexible temporal resolution  
**Issue ID:** [#1273](https://github.com/spine-tools/SpineOpt.jl/issues/1273)

### Description

When configuring a model with the same block appearing twice in temporal blocks—once with `has_free_start = true` and another with `has_free_start = false`—in combination with the `unit_lifetime` constraint, investment-related variables are reported incorrectly.  Specifically:

- The `units_invested` variable consistently reports as 0, regardless of actual investments made
- The `units_mothballed` and `units_decommissioned` variables fail to account for initial unit counts (`number_of_units`)
- Investment variables are aggregated and reported at annual resolution even when the investment block uses a different temporal resolution

**Operational Impact:** While the model's operational variables (dispatch, flows, etc.) calculate correctly, investment planning results are unreliable, making it unsuitable for multiyear capacity expansion studies with flexible temporal resolution.

### Affected Scenarios

- Multi-year investment planning without representative periods
- Models using flexible temporal resolution across different nodes
- Configurations mixing temporal blocks with different `has_free_start` parameters for the same block

### Workaround

Currently under investigation.  Until resolved, consider:

1. Avoiding mixed temporal block configurations when `unit_lifetime` constraints are active. For example, ensure that the same block is not included in both a block with `has_free_start = true` (e.g., for operation) and another with `has_free_start = false` (e.g., for investment).
1. Using uniform temporal resolution for investment blocks (e.g., 10Y) to prevent using the same temporal block as the operational blocks (e.g., 1Y).
1. Using consistent `has_free_start` settings across all temporal blocks containing the same block

### Reproducibility

A minimal reproduction case is available in the issue tracker:  [reduced_model_flexible_resolution.json](https://github.com/spine-tools/SpineOpt.jl/issues/1273)

**Last Updated:** Issue opened and currently open  
**Tracking:** https://github.com/spine-tools/SpineOpt.jl/issues/1273

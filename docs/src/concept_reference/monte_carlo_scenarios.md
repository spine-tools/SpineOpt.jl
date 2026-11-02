Defines the scenarios of the Monte Carlo algorithm, which is used when the [model\_algorithm](@ref) is `monte_carlo_algorithm`.

The value is a map from a scenario key to an array of scenario values, e.g.:

| scenario key | scenario values |
|:---|:---|
| weather\_year | \["2009", "2010"\] |
| outage\_pattern | \["1", "2"\] |

SpineOpt solves the model once for each combination of the scenario values, here four times, and writes the results of each solve separately.

A parameter value that should change between the Monte Carlo solves is given as a map from the scenario value to the value, e.g. an [availability\_factor](@ref) with one time series for `2009` and another for `2010`. If a model doesn't depend on the scenario value that changed, the solve is skipped and the previous results are reused.

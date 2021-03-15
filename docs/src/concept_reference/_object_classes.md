# Object Classes

## `commodity`

A good or product that can be consumed, produced, traded. E.g., electricity, oil, gas, water...

TODO

## `connection`

A transfer of commodities between nodes. E.g. electricity line, gas pipeline...

TODO

## `model`

An instance of SpineOpt, that specifies general parameters such as the temporal horizon.

TODO

## `node`

A universal aggregator of commodify flows over units and connections, with storage capabilities.

TODO

## `output`

A variable name from SpineOpt that can be included in a report.

TODO

## `report`

A results report from a particular SpineOpt run, including the value of specific variables.

TODO

## `stochastic_scenario`

A scenario for stochastic optimisation in SpineOpt.

Essentially, a [stochastic\_scenario](@ref) is a label for an alternative period of time,
describing one possibility of what might come to pass.
They are the basic building blocks of the scenario-based [Stochastic Framework](@ref) in *SpineOpt.jl*,
but aren't really meaningful on their own.
Only when combined into a [stochastic\_structure](@ref) using the [stochastic\_structure\_\_stochastic\_scenario](@ref)
and [parent\_stochastic\_scenario\_\_child\_stochastic\_scenario](@ref) relationships,
along with [Parameters](@ref) like the [weight\_relative\_to\_parents](@ref) and [stochastic\_scenario\_end](@ref),
they become meaningful.

## `stochastic_structure`

A group of stochastic scenarios that represent a structure.

The [stochastic\_structure](@ref) is the key component of the scenario-based [Stochastic Framework](@ref)
in *SpineOpt.jl*, and essentially represents a group of [stochastic\_scenario](@ref)s with set [Parameters](@ref).
The [stochastic\_structure\_\_stochastic\_scenario](@ref) relationship defines which [stochastic\_scenario](@ref)s
are included in which [stochastic\_structure](@ref)s, and the [weight\_relative\_to\_parents](@ref) and
[stochastic\_scenario\_end](@ref) [Parameters](@ref) define the exact shape and impact of the
[stochastic\_structure](@ref), along with the [parent\_stochastic\_scenario\_\_child\_stochastic\_scenario](@ref)
relationship.

The main reason as to why [stochastic\_structure](@ref)s are so important is, that they act as handles connecting the
[Stochastic Framework](@ref) to the modelled system.
This is handled using the [Structural relationship classes](@ref) e.g. [node\_\_stochastic\_structure](@ref),
which define the [stochastic\_structure](@ref) applied to each `object` describing the modelled system.
Connecting each system `object` to the appropriate [stochastic\_structure](@ref) individually can be a bit bothersome
at times, so there are also a number of convenience [Meta relationship classes](@ref) like the
[model\_\_default\_stochastic\_structure](@ref), which allow setting [model](@ref)-wide defaults to be used whenever
specific definitions are missing.

## `temporal_block`

A length of time with a particular resolution.

TODO

## `unit`

A conversion of one/many comodities between nodes.

TODO

## `unit_constraint`

A constraint over the flows of a specific unit.

TODO


# Stochastic Framework

Scenario-based stochastics in unit commitment and economic dispatch models typically only consider branching
scenario trees.
However, sometimes the available stochastic data doesn't span over the entire desired modelling horizon,
or all the modelled phenomena.
Especially with increasing interest in energy system integration and sector coupling,
stochastic data of consistent quality and/or length might be hard to come by.

While these data issues can be circumvented by either cloning stochastic data across multiple scenario branches
or generating dummy forecasts, they can result in inflated problem sizes.
Furthermore, Ensuring realistic correlations between generated forecasts is extremely difficult,
especially across multiple energy sectors.

The stochastic framework outlined here aims to support stochastic directed acyclic graphs (DAGs)
instead of only branching trees, allowing for scenarios to converge later on in the modelled horizon.
In addition, the framework allows for slightly different stochastic scenario graphs for different variables,
making it easier to define e.g. variables common between all stochastic scenarios.

## Key concepts

Here, we briefly describe the key concepts required to understand the stochastic structure:

1. **Stochastic scenario** is essentially just a label for an alternative period of time, describing one possiblity of what may come to pass. However, even in deterministic modelling, a single stochastic scenario is currently required for labelling the deterministic timeline.

2. **Stochastic DAG** is the directed acyclic graph describing the parent-child relationships between the stochastic scenarios. The key difference between a stochastic DAG and a traditional stochastic tree is that the scenarios are allowed to have multiple parents, making it possible to converge scenarios into each other in addition to branching.

3. **Stochastic path** is a unique sequence of stochastic scenarios for traversing the stochastic DAG. Every (finite) stochastic DAG has a limited number of *full stochastic paths* that traverse the stochastic DAG from roots (scenarios without parents) to leaves (scenarios without children). Here, we use the term stochastic path to refer to any subset of scenarios within a *full stochastic path*.

4. **Stochastic structure** is essentially a "realization" of the overlying stochastic DAG, with additional information like when the scenarios end and how much weight they are given in the objective function relative to their parents. These only become relevant when we start discussing interactions between different stochastic structures.

![DAG_fullpath_path](uploads/74e1fabd3c1d1db8c78a2c04a974e663/DAG_fullpath_path.png)

The above figure presents an example *stochastic DAG* with the individual *stochastic scenarios* labelled from `s0-s8`.
An example *full stochastic path* `[s0, s1, s5, s8]` is highlighted in red,
while an example *stochastic path* `[s2, s4, s7]` is highlighted in blue.

## General idea in brief

The major issue that arises with stochastic DAGs as opposed to stochastic trees, is that indexing constraints that
include variables from multiple time steps (henceforth referred to as dynamic constraints) cannot be done "traditionally".
With stochastic trees, constraints can always be unambiguously indexed using `(stochastic_scenario, last_time_step)`,
since all scenarios only have a single parent.
However, this is no longer the case for stochastic DAGs, since due to the possibility of converging scenarios
both advancing and backtracking through the DAG can lead to multiple scenarios, as illustrated in the figures below:

![Branching](uploads/d0cdca5d499e4d1e536a8a06d1037a45/Branching.png)
![Converging](uploads/8aac409e135f34b7270d0cf3d2aad52b/Converging.png)

The example on the left illustrates the "traditional" indexing in branching stochastic trees,
where backtracking through the tree always leads to unambiguous `(stochastic_scenario, time_step)` indices.
The example on the right shows a similar situation in a stochastic DAG, where backtracking through the DAG leads to four
different `(stochastic_scenario, time_step)` indices, and thus requires four constraints to be generated and indexed.

### Stochastic path indexing

As shown in the previous section, dynamic constraints in stochastic DAGs cannot be unambiguously indexed
using a single `(stochastic_scenario, time_step)`.
However, they *can* be unambiguously indexed using `(stochastic_path, time_step)`,
where the stochastic path is the unique sequence of scenarios traversing the DAG.
Since there are only a limited number of ways to traverse the DAG, represented by the *full stochastic paths*,
we can identify the number of unique paths necessary for constraint generation as follows:

1. Identify all unique *full stochastic paths*, meaning all the possible ways of traversing the DAG from roots to leaves.
2. Find all the stochastic scenarios that are active on all the time steps included in the constraint.
3. Find all the unique stochastic paths by intersecting the set of active scenarios with the *full stochastic paths*.
4. Generate constraints over each unique stochastic path found in step 3.

#### Example dynamic constraint generation

![ConstraintPaths](uploads/1b5b6228457fcd405812b5a50d59ed0b/ConstraintPaths.png)

The above figure shows examples of two different dynamic constraints generated in a stochastic DAG:
the red constraint including variables from timesteps `t4-t5`
and the blue constraint including variables from timesteps `t1, t3`.
The *full stochastic paths* for traversing the above DAG are as follows:

1. `[s0, s1, s5, s8]`
2. `[s0, s2, s3, s5, s8]`
3. `[s0, s2, s4, s6, s8]`
4. `[s0, s2, s4, s7, s8]`

For the red constraint, the scenarios `s5-s8` are active on the time steps `t4-t5`.
All the above *full stochastic paths* include at least two of the active scenarios,
but full paths 1 and 2 both produce an identical path `[s5, s8]`,
so the set of unique stochastic paths for the red constraint becomes:

1. `[s5, s8]`
2. `[s6, s8]`
3. `[s7, s8]`

There are no paths `[s5, s6], [s5, s7], [s6, s7]` since following the DAG one cannot start from `s5` and end up in `s6`,
even though these scenarios are active.

The blue constraint illustrates a case where the time step range is not continuous.
The active scenarios on `t1, t3` are `s1, s2, s4, s5`,
so again by comparing these to the *full stochastic paths* we get:

1. `[s1, s5]`
2. `[s2, s5]`
3. `[s2, s4]`

In this case, the *full stochastic paths* 3 and 4 both produce the path `[s2, s4]`,
so only three unique constraints need to be generated.
Again, the path `[s1, s4]` is invalid, since the DAG cannot be traversed from `s1` to `s4`.

#### Interaction between different stochastic structures

Stochastic path indexing in constraints also allows for "distorting" the stochastic DAG in different parts of the model.
As long as the stochastic DAG itself isn't changed,
meaning the parent-child relationships between scenarios and the resulting *full stochastic paths*,
we can actually define different stochastic structures and still be able to handle constraint generation between them.
This is due to the fact that when determining the stochastic paths,
it makes no difference whether we're looking at the same stochastic structure at different time steps,
or at two stochastic structures, one of which has been delayed, on the same time step.
This is illustrated by the figure below:

![DelayedStochasticPaths](uploads/53fa6893a9f72307a9aa795c1296020a/DelayedStochasticPaths.png)

The above represents constraint generation over two stochastic structures,
where the lower structure has been delayed in respect to the above structure.
Nevertheless, the procedure for finding the stochastic paths for the constraints remains identical to the previous example:

1. Identify all unique *full stochastic paths*, meaning all the possible ways of traversing the DAG. As long as the DAG remains the same between all the involved stochastic structures, the pathing remains the same.
2. Find all the stochastic scenarios that are active on all the stochastic structures and time steps included in the constraint.
3. Find all the unique stochastic paths by intersecting the set of active scenarios with the *full stochastic paths*.
4. Generate constraints over each unique stochastic path found in step 3.

## Implementation

### New stochastic data objects

#### Stochastic `object_classes`

- [stochastic\_scenario](@ref) is essentially just a name for each possible scenario.
- [stochastic\_structure](@ref) represents a group of `stochastic scenarios` with certain parameters. Convenience class aimed to make defining nodal `stochastic structures` easier.

#### Stochastic `relationship_classes`

- [parent\_stochastic\_scenario\_\_child\_stochastic\_scenario](@ref) defines the stochastic DAG, and is a `model` level property.
- [stochastic\_structure\_\_stochastic\_scenario](@ref) defines the `stochastic scenarios` included in each [stochastic\_structure](@ref), as well as holds all related [Parameters](@ref).
- [node\_\_stochastic\_structure](@ref) defines which `stochastic structures` are enforced for which `nodes`. Each [node](@ref) must be connected to exactly one [stochastic\_structure](@ref), otherwise the model throws an error.

#### `parameters` for `stochastic_structure__stochastic_scenario`

- **[stochastic\_scenario\_end](@ref)** is a `Duration` type parameter that tells when the [stochastic_scenario](@ref) ends in relation to the current `window_start`. When defined, the [stochastic\_scenario](@ref) ends at the defined point in time, and spawns its children according to [parent\_stochastic\_scenario\_\_child\_stochastic\_scenario](@ref), if any. **Note that this means the children are included in the [stochastic\_structure](@ref), even without an explicit relationship!** If [stochastic\_scenario\_end](@ref) isn't defined, the [stochastic_scenario](@ref) is assumed to go on indefinetely. 
- **[weight\_relative\_to\_parents](@ref)** determines the coefficient of the [stochastic\_scenario](@ref) relative to its parents in the objective function. The actual weight of each [stochastic\_scenario](@ref) that goes into the objective function is calculated as:
```
# For root `stochastic_scenarios` (meaning no parents)

weight(scenario) = weight_relative_to_parents(scenario)

# If not a root `stochastic_scenario`

weight(scenario) = sum([weight(parent) * weight_relative_to_parents(scenario)] for parent in parents)
```

### What do I need to get a model running?

1. Define at least one [stochastic\_scenario](@ref) and at least one [stochastic\_structure](@ref)
2. Define at least one [stochastic\_structure\_\_stochastic\_scenario](@ref), and the [weight\_relative\_to\_parents](@ref) parameters. Note that if any of your `stochastic scenarios` have the [stochastic\_scenario\_end](@ref) parameter defined, you also need to define [weight\_relative\_to\_parents](@ref) for their children!
3. Connect every [node](@ref) to exactly one [stochastic\_structure](@ref) via the [node\_\_stochastic\_structure](@ref) relationship.

Unless your `stochastic scenarios` form a stochastic DAG, the [parent\_stochastic\_scenario\_\_child\_stochastic\_scenario](@ref) relationship is not necessary. If it's not defined, all `stochastic scenarios` are assumed to have neither parents nor children.

### New file `generate_stochastic_structure`

This file contains most of the functions used to generate the stochastic structure based on the relevant objects
and parameters in the database, e.g. finding the *full stochastic paths* through the defined stochastic DAG and
forming the `stochastic_structures` and their parameters (referred to as `stochastic_DAGs` in the code...).
Also includes functions for mapping the `stochastic_scenarios` of `stochastic_structures` to their corresponding
`time_slices`, functions for accessing the full `(node, stochastic_scenario, time_slice)` and
`(unit, stochastic_scenario, time_slice)` index sets, as well as generating the `node__stochastic_scenario` and
`unit_stochastic_scenario` `RelationshipClasses` as well as the `node_stochastic_scenario_weight` an
 `unit_stochastic_scenario_weight` `Parameters` for said `RelationshipClasses`.

- NOTE: The terminology could still be made clearer. In the code, `DAG` is used to refer to the "realized" `DAG` with all the parameters in place, which corresponds better with how a `stochastic_structure` is defined in this wiki.

### Constraint generation using stochastic path indexing

Every time a constraint might refer to variables either on different time steps or on different `stochastic scenarios`
(meaning different `nodes` or `units`), the constraint needs to use stochastic path indexing in order to be correctly
generated for arbitrary stochastic DAGs.
In practise, this means following the procedure outlined in the previous sections:

1. Identify all unique *full stochastic paths*, meaning all the possible ways of traversing the DAG. This is done along with generating the stochastic structure, so no real impact on constraint generation.
2. **Find all the `stochastic scenarios` that are active on all the `stochastic structures` and `time slices` included in the constraint.**
3. **Find all the unique stochastic paths by intersecting the set of active scenarios with the *full stochastic paths*.**
4. Generate constraints over each unique stochastic path found in step 3.

Steps 2 and 3 are the crucial ones, and are currently handled by separate `constraint_<constraint_name>_indices` functions.
Essentially, these functions go through all the variables on all the time steps included in the constraint,
collect the set of active `stochastic_scenarios` on each time step,
and then determine the unique active stochastic paths on each time step.
The functions pre-form the index set over which the constraint is then generated in the `add_constraint_<constraint_name>` functions.
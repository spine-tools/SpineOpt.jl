# How does SpineOpt perceive time?

This section answers the following questions:
1. What are time slices?
2. What are time slice convenience functions?
3. How can they be used?

## From temporal blocks to time slices

Within the [run\_spineopt](@ref) function, one key step is to generate the temporal structure for the model.
The process goes as follows:
1. Generate the temporal structure
   1. Translate the [temporal\_block](@ref)s in the input DB to a set of `TimeSlice` objects
   1. Create relationships between these `TimeSlice` objects
      - Relationships between two consecutive time slices (`t_before` ending right when `t_after` starts)
      - Relationship between overlapping time slices (`t_short` contained in `t_long`)
   1. Store all the above within `m.ext[:spineopt].temporal_structure`
1. Build the model
   1. Query `m.ext[:spineopt].temporal_structure` to collect generated `TimeSlice` objects and relationships
   1. Use them for indexing variables and generating constraints

To translate the [temporal\_block](@ref)s into `TimeSlice` objects,
we basically look at the value of [model\_start](@ref) and [model\_end](@ref) for the [model](@ref) object,
as well as the value of the [resolution](@ref) for the different [temporal\_block](@ref) objects.
Then we build as many `TimeSlice`s as needed to cover the period between [model\_start](@ref) and [model\_end](@ref) at each [resolution](@ref).
Note that a `TimeSlice` is simply a *slice* of time with a start and an end.


!!! note
    `m` is the `JuMP.Model` object that SpineOpt builds and solves using `JuMP`.
    It has a field called `ext` which is s `Dict` where one can store more data.
    `m.ext[:spineopt].temporal_structure` is just a `Dict` where we store data related to the temporal structure.

## What are the time slice convenience functions?

To facilitate querying the temporal structure, we have developed the following convenience functions:

- [t\_before\_t](@ref)
- [t\_overlaps\_t](@ref)
- [t\_in\_t](@ref)

!!! note
    To further figure out what the time slice convenience functions do,
    you can play around with them.
    To do so, you first need to make a database (e.g. in Spine Toolbox).
    Then you can call `run_spineopt` with that database and collect the model `m`.
    If you are impatient you do not even need to solve the model, you can pass `optimize=false`
    as keyword argument to `run_spineopt`.
    And then you can start calling the time slice convenience functions with `m`
    (e.g. `t_in_t`).

## How can the time slice convenience functions be used?

When building constraints you typically want to know which `TimeSlice`s come after/before another,
overlap another, or contain/are contained in another. You can obtain this by calling the above convenience functions.

For example, say you're generating a constraint at a 3-hour resolution.
This means you have a `TimeSlice` in your constraint index, and that `TimeSlice` covers 3 hours.
Now, say you want to sum a certain variable over those 3 hours in your constraint expression.
You need to know all the `TimeSlice`s contained in the one from your constraint index. You can find out this
by calling [t\_in\_t](@ref) with it.

A fool proof way of writing the constraint is to always take the highest resolution among the overlapping `TimeSlice`s to generate the constraint indices. The other `TimeSlice`s can then be obtained from [t\_overlaps\_t](@ref).

More information can be found in the [Write a constraint for SpineOpt](@ref) section.
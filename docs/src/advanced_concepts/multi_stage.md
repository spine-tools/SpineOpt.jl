# Multi-stage optimisation

!!! note
    This section describes how to run multi-stage optimisations with SpineOpt using the [stage](@ref) class -
    not to be confused with the rolling horizon optimisation technique described in [Temporal Framework](@ref),
    nor the Benders decomposition algorithm described in [Decomposition](@ref).

!!! warning
    This feature is experimental. It may change in future versions without notice.

By default, SpineOpt is solved as a 'single-stage' optimisation problem.
However you can add *additional* stages to the optimisation by creating [stage](@ref) objects in your DB.

To motivate this discussion, say you want to model a storage over a year with hourly resolution.
The model is large, so you would like to solve it using a rolling horizon of, say, one day - so it solves quickly
(see [roll\_forward](@ref) and the [Temporal Framework](@ref) section).
But this wouldn't capture the long-term value of your storage!

To remediate this, you can introduce an additional 'stage' that solves the entire year at once
with a lower temporal resolution (say, one day instead of one hour),
and then fixes the storage level at certain points for your higher-resolution rolling horizon model.
Both models, the year-long model at daily resolution and the rolling horizon model at hourly resolution,
will solve faster than the year-long model at hourly resolution - hopefully much faster -
leading to a good compromise between speed and accuracy.

So how do you do that? You use a [stage](@ref).

## The [stage](@ref) class

In SpineOpt, a [stage](@ref) is an additional optimisation model that fixes certain [output](@ref)s
for another set of models declared as their *children*.

The children of a [stage](@ref) are defined via [stage\_\_child\_stage](@ref) relationships
(with the parent [stage](@ref) in the first dimension).
If a [stage](@ref) has no [stage\_\_child\_stage](@ref) relationships as a parent,
then it is assumed to have only one children: the [model](@ref) itself.

The [output](@ref)s that a [stage](@ref) fixes for its children are defined via [stage\_\_output](@ref)
relationships. By default, the [output](@ref) is fixed at the *end* of each child's rolling window.
However, you can fix it at other points in time by specifying the [output\_resolution](@ref) parameter
as a duration (or array of durations) relative to the *start* of the child's rolling window.

For example, if you specify an [output\_resolution](@ref) of `1 day`,
then the [output](@ref) will be fixed at one day after the child's window start.
If you specify something like `[1 day, 2 days]`, then it will be fixed at one day after the window start,
and then at two days after that (i.e., three days after the window start).

The optimisation model that a [stage](@ref) solves is given by the [stage\_scenario](@ref) parameter value,
which must be a scenario in your DB.

And that's basically it!

## Example

In case of the year-long storage model with hourly resolution, here is how you would do it.

First, the basic setup:
1. Create your [model](@ref).
1. Specify [model\_start](@ref) and [model\_end](@ref) for your [model](@ref) to cover the year of interest.
1. Specify [roll\_forward](@ref) for your [model](@ref) as `1 day`.
1. Create a [temporal\_block](@ref) called "flat".
1. Specify [resolution](@ref) for your [temporal\_block](@ref) as `1 hour`.
1. Create a [model\_\_default\_temporal\_block](@ref) between your [model](@ref) and your [temporal\_block](ref)
   (to keep things simple, but of course you can use [node\_\_temporal\_block](@ref), etc., as needed).
1. Create the rest of your model (the storage [node](@ref), etc.)

With the above, you will have a rolling-horizon model that would probably solve in reasonable time
but wouldn't capture the long-term value of your storage.

Now, the 'stage' stuff:
1. Create an alternative called "lt_storage_alt".
1. Create a scenario called "lt_storage_scen" with the "lt_storage_alt" alternative in the highest rank.
1. Create a [stage](@ref) called "lt_storage".
1. (Don't create any [stage\_\_child\_stage](@ref) relationsips - the only child is the [model](@ref) - plus you don't have/need other [stage](@ref)s).
1. Create a [stage\_\_output](@ref) between your [stage](@ref) and the "node_state" [output](@ref).
1. Don't specify [output\_resolution](@ref) so the output is fixed at the end of the [model](@ref)'s rolling window.
1. Specify [roll\_forward](@ref) for your [model](@ref) in the "lt_storage_alt" alternative as `nothing` - so the model doesn't roll - the entire year is solved at once.
1. Specify [resolution](@ref) for the "flat" [temporal\_block](@ref) in the "lt_storage_alt" alternative as `1 day`.
1. Specify [stage\_scenario](@ref) for the "lt_storage" [stage](@ref) as `"lt_storage_scen"`.


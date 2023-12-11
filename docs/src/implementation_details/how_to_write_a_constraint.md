```@raw html
<script type="module">
  import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.esm.min.mjs';
</script>
```

# Write a constraint for SpineOpt

## Introduction

Writing a constraint in SpineOpt is a bit of an art.
This is possibly due to the enormous flexibility that is allowed
for the temporal and stochastic structures,
which might lead to situations some consider to be... unnatural.

This guide will demonstrate an almost systematic way to do it, but it's not a silver-bullet kind of recipe.
Most probably you will need to adapt it to your particular needs the day you dare writing your first constraint.

What has proven useful to me is to combine a little bit of a theoretical approach with a more of a practical approach.
In other words, I begin by following certain predetermined steps, see what comes out of it for a meaningful example system,
and then refine. Hopefully the process converges at some point, and because I have been looking at the output
for an example system, I almost already have the unit-test that will consolidate the whole process and make me look like
a good programmer.

Let's begin! We will be trying to write a simplified version of the unit capacity constraint, looking as follows:

```math
\begin{aligned}
& v^{unit\_flow}_{(u,n,d,s,t)} \leq p^{unit\_capacity}_{(u,n,d,s,t)} \cdot \left( v^{units\_on}_{(u,s,t)} - \left(1 - p^{shut\_down\_limit}_{u,n,d,s,t} \right) \cdot v^{units\_shut\_down}_{(u,s,t+1)} \right) \\
& \forall (u, n, d) \in unit\_\_from\_node \cup unit\_\_to\_node: p^{unit\_capacity}_{(u,n,d)} \neq null \\
& \forall (s, t)
\end{aligned}
```

In other words, the [unit\_flow](@ref) between a [unit](@ref) and a [node](@ref) has to be lower than or equal to:
- the specified [unit\_capacity](@ref), if the [unit](@ref) is online and not shutting down in the next period;
- the [unit\_capacity](@ref) multiplied by the [shut\_down\_limit](@ref), if the [unit](@ref) is shutting down in the next period;
- zero, if the [unit](@ref) is offline.

Note that we ignore the [start\_up\_limit](@ref) in this formulation, just for simplicity.
(And actually, it looks like we also assume that a unit cannot start up and shut down in the same period.)

## First steps

So how do we proceed? Well, we said above that there were some kind of steps that one could follow.
They actually look like this:

1. Collect the constraint indices.

   a. Collect the 'spatial' indices.

   b. Collect the 'temporal' indices.

   c. Collect the 'stochastic' indices.

2. Write the constraint expression.

That's it!? Well, it actually is a bit more complex than that. Let's expand...

### Collect the constraint indices

#### Collect the 'spatial' indices

This is probably the simplest part, as you just need to identify the system elements
that would be affected by the constraint.
In our case, it will probably be the tuples of [unit](@ref) and [node](@ref)
associated via [unit\_\_from\_node](@ref) and/or [unit\_\_to\_node](@ref)
for which [unit\_capacity](@ref) is specified.

#### Collect the 'temporal' indices

This is a bit harder. Here you need to answer two questions:
1. how often the constraint needs to be enforced;
2. for each of those moments, how far in time do we need to look in order to enforce the constraint.

To answer the first question, the first step is to understand where the different variables involved
in your constraint get their temporal resolution from. In our case, we have [unit\_flow](@ref),
[units\_on](@ref) and [units\_shut\_down](@ref). The former gets its resolution from the associated [node](@ref),
via [node\_\_temporal\_block](@ref); whereas the two latter get it from the [unit](@ref),
via [units\_on\_\_temporal\_block](@ref).

If all [node](@ref)s and [unit](@ref)s had the same temporal resolution, there would be no questions to be asked.
We'd just take that unique resolution and enforce the constraint at that rate.
But since each [unit](@ref) and [node](@ref) is allowed to have their
own temporal resolutions (that's right, *resolutions* in plural), there are several questions to be asked:
What happens if, e.g., the [unit](@ref) has higher resolution than the [node](@ref) (or vice versa)?
What happens if the [unit](@ref) and/or the [node](@ref) have multiple resolutions running in parallel?
What happens if their resolutions change over time?

Ultimately, the question we need to ask ourselves is what is the 'lowest-resolution way' in which we can combine
the individual resolutions of all our 'spatial' indices so we never miss a period where we should be enforcing the
constraint.
In our case, we need to guarantee that the flow between a [unit](@ref) and a [node](@ref)
is *never* higher than the [unit\_capacity](@ref). So it looks like we should be taking the *highest* resolution
of the [unit\_flow](@ref) variable.

But we also need to guarantee that the flow is lower than the [unit\_capacity](@ref) times the
[shut\_down\_limit](@ref) if the [unit](@ref) is shutting down in the next period. How does that affect the
resolution of the constraint? Is it still Ok to use the resolution of [unit\_flow](@ref)?
What happens if [units\_on](@ref) has higher resolution than [unit\_flow](@ref)?
Would we violate this last part of the constraint eventually?

In doubt, something that could work is to take the highest resolution of all the individual resolutions
involved. That should ensure that we don't miss any time-slice, but at the same time it might not be
the most efficient...

Now, to answer the second question, how far in time do we need to look,
we typically just need to check out our constraint expression.
In our case, we need to look at the current time-slice, but also at the *next* time-slice to check if the
unit is shutting down in that time-slice.

So in our case, the 'temporal' indices will be tuples of (current time-slice, next time-slice).

#### Collect the 'stochastic' indices

Primer on SpineOpt's stochastic framework (more details in the [Stochastic Framework](@ref) section).
In SpineOpt, each [unit](@ref) and [node](@ref) has one (and only one) [stochastic\_structure](@ref) associated via
[units\_on\_\_stochastic\_structure](@ref) and [node\_\_stochastic\_structure](@ref), respectively -
which represents their 'stochastic dimension'.

But what *is* a [stochastic\_structure](@ref)?
To answer this question, let's consider a directed acyclic graph (DAG)
where the vertices are all the [stochastic\_scenario](@ref)s in the model, 
and the edges are given by the [parent\_stochastic\_scenario\_\_child\_stochastic\_scenario](@ref) relationships.
A [stochastic\_structure](@ref) is basically defining a *subset* of this DAG, including only those
[stochastic\_scenario](@ref)s associated to it via [stochastic\_structure\_\_stochastic\_scenario](@ref),
and where the point in time where each [stochastic\_scenario](@ref) gives way
to their children is determined by the [stochastic\_scenario\_end](@ref) parameter.
For example:

```@raw html
<div class="mermaid">
    flowchart LR;
    scen1--06:00-->scen2a;
    scen1--06:00-->scen2b;
    scen1--06:00-->scen2c;
    scen2a--15:00-->scen3;
    scen2b--15:00-->scen3;
    scen2c--12:00-->scen3;
</div>
```

Above we have `scen1` branching into `scen2a`, `scen2b`, and `scen2c`; and then all these converging into `scen3`.
Note that `scen2c` ends a bit earlier than `scen2a` and `scen2b` - just to make it more
interesting.

So essentially, in a structure like the above, a given range of time may 'coexist' in many
scenario branches - or 'paths', as we like to call them in SpineOpt.
For example, the interval `[15:00, 18:00]` exists in paths
`scen2a -> scen3` and `scen2b -> scen3` - but not in `scen2c -> scen3`.

Now, in the context of a SpineOpt constraint, we will have a [stochastic\_structure](@ref) like the above,
given by the 'spatial' indices, and a range of time determined by the 'temporal' ones.
So we will find our range of time replicated in multiple paths.
That means the constraint needs to be enforced in each of those paths, or, in other words,
each of those paths has to be a different 'stochastic' index for our constraint.

### Write the constraint expression

Here you just write the constraint expression using JuMP - so if you're moderately familiar with JuMP, that's a good
start.

But there is one big caveat. You will of course need to include SpineOpt variables in your expression,
and each variable has their own indexing.
There is no guarantee that the constraint indices you've selected in the previous step will match those
of all the variables in your constraint - so for each variable you want to include,
you will need to somehow translate your constraint indices into that variable.

The good news is for each variable in SpineOpt, we have a corresponding function that returns all the
indices of that variable. The even better news is the same function also allows you to do some filtering
on each dimension, so you can easily obtain all the indices matching a condition.
For example, you can tell to this function, 'give me all the [unit\_flow](@ref) indices
where the [unit](@ref) is `u`, the [node](@ref) is a member of the node group `ng`,
the time-slice is one of those *contained* in `t`, and
the [stochastic\_scenario](@ref) is one of the stochastic path `s_path`'.

So basically you can use that function to obtain all the indices of
the variable that match the indices of your constraint. Yes, it can be more than one!
That's why most of the terms in SpineOpt constraints are summations. For example, the summation, over all
the [unit\_flow](@ref) variable's indices, `i`, matching the constraint index; of the product between
a certain parameter and the [unit\_flow](@ref) variable for that `i`.

Hopefully all the above will become clearer with an example - so let's dive into it!

## Into the code

### The test system

I said above that I liked to combine a theoretical approach with a more of a practical approach.
I guess what I meant is I don't want to do too much thinking - I want to constantly validate my code
against a meaningful example.

So let's try and define a test system that triggers the creation of our constraint,
is complex enough so we don't miss any relevant cases, but not that complex that we're unable to diagnose it.
Maybe something like the below:

```julia
using Dates
using SpineInterface
using SpineOpt

url_in = "sqlite:///my_unit_flow_capacity_constraint.sqlite"

import_data(url_in, SpineOpt.template(), "Add template")
import_data(
    url_in,
    "Add test data";
    objects=[
        ("model", "simple"),
        ("temporal_block", "hourly"),
        ("temporal_block", "2hourly"),
        ("temporal_block", "3hourly"),
        ("stochastic_scenario", "realisation"),
        ("stochastic_scenario", "forecast1"),
        ("stochastic_scenario", "forecast2"),
        ("stochastic_structure", "one_stage"),
        ("stochastic_structure", "two_stage"),
        ("unit", "pwrplant"),
        ("node", "fuel"),
        ("node", "elec"),
    ],
    relationships=[
        ("parent_stochastic_scenario__child_stochastic_scenario", ("realisation", "forecast1")),
        ("parent_stochastic_scenario__child_stochastic_scenario", ("realisation", "forecast2")),
        ("stochastic_structure__stochastic_scenario", ("one_stage", "realisation")),
        ("stochastic_structure__stochastic_scenario", ("two_stage", "realisation")),
        ("stochastic_structure__stochastic_scenario", ("two_stage", "forecast1")),
        ("stochastic_structure__stochastic_scenario", ("two_stage", "forecast2")),
        ("unit__from_node", ("pwrplant", "fuel")),
        ("unit__to_node", ("pwrplant", "elec")),
        ("node__temporal_block", ("fuel", "3hourly")),
        ("node__temporal_block", ("elec", "hourly")),
        ("units_on__temporal_block", ("pwrplant", "2hourly")),
        ("node__stochastic_structure", ("fuel", "one_stage")),
        ("node__stochastic_structure", ("elec", "two_stage")),
        ("units_on__stochastic_structure", ("pwrplant", "one_stage")),
    ],
    object_parameter_values=[
        ("model", "simple", "model_start", unparse_db_value(DateTime("2023-01-01T00:00"))),
        ("model", "simple", "model_end", unparse_db_value(DateTime("2023-01-01T06:00"))),
        ("temporal_block", "hourly", "resolution", unparse_db_value(Hour(1))),
        ("temporal_block", "2hourly", "resolution", unparse_db_value(Hour(2))),
        ("temporal_block", "3hourly", "resolution", unparse_db_value(Hour(3))),
        ("temporal_block", "hourly", "block_end", unparse_db_value(DateTime("2023-01-01T09:00"))),
    ],
    relationship_parameter_values=[
        (
            "stochastic_structure__stochastic_scenario",
            ("two_stage", "realisation"),
            "stochastic_scenario_end",
            unparse_db_value(Hour(6))
        ),
        ("unit__from_node", ("pwrplant", "fuel"), "unit_capacity", 200),
        ("unit__to_node", ("pwrplant", "elec"), "unit_capacity", 100),
        ("unit__to_node", ("pwrplant", "elec"), "shut_down_limit", 0.2),
    ],
)
```

Whoa, what's all that stuff!?

Basically, what we're doing here is creating a SpineOpt [model](@ref) called `simple`, starting January first 2023
at 00:00 and ending at 06:00. This `simple` [model](@ref) has three [temporal\_block](@ref)s,
`1hourly`, `2hourly` and `3hourly`, with one-, two-, and three-hour resolution respectively;
and `1hourly` ends at 09:00 (three hours later than the [model](@ref) - so it's like a look-ahead).
It also has three [stochastic\_scenario](@ref)s,
`realisation`, `forecast1` and `forecast2`, where the two latter are children of the former;
and two [stochastic\_structure](@ref)s, `one_stage`,
including only `realisation`, and `two_stage`, including all three of them and with `realisation` ending 6 hours
after the model starts.

The [model](@ref) consists of two [node](@ref)s, `fuel` and `elec`, with a [unit](@ref) in between,
`pwrplant`. The `fuel` [node](@ref) is modelled at three-hour resolution and one-stage stochastics;
the `elec` [node](@ref) is modelled at one-hour resolution and two-stage stochastics;
and the `pwrplant` [unit](@ref) is modelled at two-hour resolution and one-stage stochastics.
Finally, the [unit\_capacity](@ref) is 200 for flows coming to the `pwrplant` from the `fuel` [node](@ref),
and 300 for flows going from the `pwrplant` to the `elec` [node](@ref);
the [shut\_down\_limit](@ref) is 0.2 for the `elec` [node](@ref) flows
(and none, thus irrestricted, for the `fuel` [node](@ref) flows).

!!! note
    If you have trouble understanding the above, maybe (unfortunately) it means you're not quite ready yet
    to write your own constraints in SpineOpt.
    My suggestion would be to go through the different tutorials and come back after that.

### The actual constraint code

I guess it's about time we finally start writing our constraint.
We will split our code in two functions:

- A function that receives a JuMP `Model` object `m` and returns an `Array` containing all the constraint indices.
- A function that receives a JuMP `Model` object `m` and adds the constraint to it.

Let's start with dummy versions of these functions so we can appreciate the infrastructure:


```julia
using JuMP

function my_unit_flow_capacity_constraint_indices(m)
    []
end

function add_my_unit_flow_capacity_constraint!(m)
    m.ext[:spineopt].constraints[:my_unit_flow_capacity] = Dict(
        ind => @constraint(m, 0 <= 0)
        for ind in my_unit_flow_capacity_constraint_indices(m)
    )
end
```

The `my_unit_flow_capacity_constraint_indices` is at the moment returning no indices.
Then, for each of those indices (!), `add_my_unit_flow_capacity_constraint` is creating the constraint `0 <= 0`
and adding it to the model. So yeah, not very useful, but probably good enough to get started.

!!! note
    In `add_my_unit_flow_capacity_constraint!`, the part that adds the constraint to the model is just the
    `@constraint(m, ...)` bit. The rest of the machinery is mainly for inspection purposes.
    We build a dictionary that maps each constraint index to
    the corresponding constraint, and store that dictionary in a specific location within the `m.ext` dictionary.
    Whit this we can easily access the generated constraints via the model object `m` that gets returned
    by `run_spineopt`.

#### The function that yields the constraint indices

##### Space

Let's develop `my_unit_flow_capacity_constraint_indices` so it returns at least something. Let's make it return
the 'spatial' indices.

We will start very slow.
We are looking for the tuples of [unit](@ref) and [node](@ref)
associated via [unit\_\_from\_node](@ref) and/or [unit\_\_to\_node](@ref)
for which [unit\_capacity](@ref) is specified.

So we could try something like this:

```julia
function my_unit_flow_capacity_constraint_indices(m)
    [(unit=u, node=n, direction=d) for (u, n, d) in unit__from_node()]
end
```

Will the above work? Well, it's only considering flows *from* a [node](@ref) to a [unit](@ref).
We also need the flows in the opposite direction. Let's try again:

```julia
function my_unit_flow_capacity_constraint_indices(m)
    [
        (unit=u, node=n, direction=d)
        for (u, n, d) in vcat(unit__from_node(), unit__to_node())
    ]
end
```

That seems better. We are concatenating the output of `unit__from_node()` and `unit__to_node()` using
Julia's `vcat` function.
But we also need to make sure that the [unit\_capacity](@ref) is specified for our
[unit](@ref)/[node](@ref)(/`direction`) combination. So we need to add a condition to our array comprehension:

```julia
function my_unit_flow_capacity_constraint_indices(m)
    [
        (unit=u, node=n, direction=d)
        for (u, n, d) in vcat(unit__from_node(), unit__to_node())
        if unit_capacity(unit=u, node=n, direction=d) != nothing
    ]
end
```
That should work.

So we have a function that returns the 'spatial' indices! We can still do a little better than that though.
Turns out this kind of computation is so common, that we have a SpineInterface function that can be used as a shortcut,
called `indices`. The above can be rewritten simply as:

```julia
using SpineInterface

function my_unit_flow_capacity_constraint_indices(m)
    [(unit=u, node=n, direction=d) for (u, n, d) in indices(unit_capacity)]
end
```

So let's see what's happening!

###### [The code that shows the constraints being generated](@id the_code_that_shows)

The `run_spineopt` function
has an optional keyword argument called `add_constraints` that we can use to try out our constraint code.
Basically, if we give this argument a function, the function will be called with the model object
at the moment of adding constraints. So we can try giving it the `add_my_unit_flow_capacity_constraint!` function:

```julia
using SpineOpt

m = run_spineopt(
    url_in,
    nothing;
    add_constraints=add_my_unit_flow_capacity_constraint!,
    optimize=false,
    log_level=0,
)

my_unit_flow_capacity_constraint = m.ext[:spineopt].constraints[:my_unit_flow_capacity]
for k in sort(collect(keys(my_unit_flow_capacity_constraint)))
    println(my_unit_flow_capacity_constraint[k])
end
```
Note that we are also passing `nothing` as the second argument (the output URL),
because we don't want to write results.
In fact, we don't even want to solve (`optimize=false`), we are just interested in inspecting our constraint.
We also aren't very interested in the log (`log_level=0`).

And after that, we are just printing all the constraints that got generated ordered by index.
At the moment it should be printing:

```
my_unit_flow_capacity(unit = pwrplant, node = fuel, direction = from_node) : 0 ≤ 0
my_unit_flow_capacity(unit = pwrplant, node = elec, direction = to_node) : 0 ≤ 0
```

which (I hope you agree) means we're good.

##### Time

Let's add the 'temporal' indices. We know that we need two of such indices: the *current* time-slice,
and the *next* time-slice. The *current* time-slice we will use to access both
[unit\_flow](@ref) and [units\_on](@ref), and the *next* to access [units\_shut\_down](@ref).

To collect time-slices, we will be using a special function from SpineOpt called `time_slice`.
This function receives a model object `m` and returns an array with all the time-slices in that model -
but it also has two optional keyword arguments, `temporal_block` and `t`, to filter the result.
- If you specify `temporal_block` as a [temporal\_block](@ref) or array of [temporal\_block](@ref)s,
  you get only time-slices in those blocks.
- If you specify `t` as a time-slice or array of time-slices, you get only those time-slices (if they also pass
  the `temporal_block` filter above.)

So let's try and find our *current* time-slice.
Let's start simple. Let's begin by taking only the time-slices associated to the [unit](@ref).

```julia
function my_unit_flow_capacity_constraint_indices(m)
    [
        (unit=u, node=n, direction=d, t=t)
        for (u, n, d) in indices(unit_capacity)
        for t in time_slice(m; temporal_block=units_on__temporal_block(unit=u))
    ]
end
```

Let's see.
We first call `units_on__temporal_block` while passing our [unit](@ref) 'spatial' index `u`, via the `unit` argument.
This returns an `Array` with the [temporal\_block](@ref)s associated to that [unit](@ref), that
we then pass to the `time_slice` function via the `temporal_block` argument.
So we end up obtaining all the time-slices in [temporal\_block](@ref)s associated to `u`.

If we rerun [the code that shows the constraints](@ref the_code_that_shows), we see the following:

```julia
my_unit_flow_capacity(unit = pwrplant, node = elec, direction = to_node, t = 2023-01-01T00:00~>2023-01-01T02:00) : 0 ≤ 0
my_unit_flow_capacity(unit = pwrplant, node = elec, direction = to_node, t = 2023-01-01T02:00~>2023-01-01T04:00) : 0 ≤ 0
my_unit_flow_capacity(unit = pwrplant, node = elec, direction = to_node, t = 2023-01-01T04:00~>2023-01-01T06:00) : 0 ≤ 0
my_unit_flow_capacity(unit = pwrplant, node = fuel, direction = from_node, t = 2023-01-01T00:00~>2023-01-01T02:00) : 0 ≤ 0
my_unit_flow_capacity(unit = pwrplant, node = fuel, direction = from_node, t = 2023-01-01T02:00~>2023-01-01T04:00) : 0 ≤ 0
my_unit_flow_capacity(unit = pwrplant, node = fuel, direction = from_node, t = 2023-01-01T04:00~>2023-01-01T06:00) : 0 ≤ 0
```

So we are getting time-slices at two-hour resolution. This makes sense, because the `pwrplant` [unit](@ref) is
(only) associated to the `2hourly` [temporal\_block](@ref), remember? However, does it work?
Well, we know the `elec` [node](@ref) is associated to the `1hourly` [temporal\_block](@ref),
and that means we have [unit\_flow](@ref) variables at one-hour resolution -
because [unit\_flow](@ref) gets its resolution from the [node](@ref), right?
We can't just enforce the constraint every two hours if the flows are tracked every *one* hour!

So taking the time-slices of the [unit](@ref) is clearly insufficient, because we happen to have a [node](@ref)
at a higher resolution.

Let's try to take the time-slices of the [node](@ref) then:
```julia
function my_unit_flow_capacity_constraint_indices(m)
    [
        (unit=u, node=n, direction=d, t=t)
        for (u, n, d) in indices(unit_capacity)
        for t in time_slice(m; temporal_block=node__temporal_block(node=n))
    ]
end
```

After running [the code that shows the constraints](@ref the_code_that_shows), we observe:

```
my_unit_flow_capacity(unit = pwrplant, node = elec, direction = to_node, t = 2023-01-01T00:00~>2023-01-01T01:00) : 0 ≤ 0
my_unit_flow_capacity(unit = pwrplant, node = elec, direction = to_node, t = 2023-01-01T01:00~>2023-01-01T02:00) : 0 ≤ 0
my_unit_flow_capacity(unit = pwrplant, node = elec, direction = to_node, t = 2023-01-01T02:00~>2023-01-01T03:00) : 0 ≤ 0
my_unit_flow_capacity(unit = pwrplant, node = elec, direction = to_node, t = 2023-01-01T03:00~>2023-01-01T04:00) : 0 ≤ 0
my_unit_flow_capacity(unit = pwrplant, node = elec, direction = to_node, t = 2023-01-01T04:00~>2023-01-01T05:00) : 0 ≤ 0
my_unit_flow_capacity(unit = pwrplant, node = elec, direction = to_node, t = 2023-01-01T05:00~>2023-01-01T06:00) : 0 ≤ 0
my_unit_flow_capacity(unit = pwrplant, node = elec, direction = to_node, t = 2023-01-01T06:00~>2023-01-01T07:00) : 0 ≤ 0
my_unit_flow_capacity(unit = pwrplant, node = elec, direction = to_node, t = 2023-01-01T07:00~>2023-01-01T08:00) : 0 ≤ 0
my_unit_flow_capacity(unit = pwrplant, node = elec, direction = to_node, t = 2023-01-01T08:00~>2023-01-01T09:00) : 0 ≤ 0
my_unit_flow_capacity(unit = pwrplant, node = fuel, direction = from_node, t = 2023-01-01T00:00~>2023-01-01T03:00) : 0 ≤ 0
my_unit_flow_capacity(unit = pwrplant, node = fuel, direction = from_node, t = 2023-01-01T03:00~>2023-01-01T06:00) : 0 ≤ 0
```

So now we're getting time-slices at one-hour resolution on the `elec` side, and three-hour on the `fuel` side.
This seems enough to enforce that the [unit\_flow](@ref) is never higher than the
[unit\_capacity](@ref).
However, we also need to enforce that the [unit\_flow](@ref) is never higher than the [unit\_capacity](@ref) times
the [shut\_down\_limit](@ref) if the unit is shutting down the next period.
Since the unit is able to shut-down 'at two-hour resolution' so to say, clearly taking the
three-hour resolution on the `fuel` side is not enough to check if the [unit](@ref) is shutting down in the next period.
Worst-case scenario, the [unit](@ref) could be shutting down in the *current* period, because the current period
lasts three hours and the [unit](@ref) can shut down after two hours!

So it looks like we need to take the time-slices from the [unit](@ref) *and* the [node](@ref).
We could do it this way:

```julia
function my_unit_flow_capacity_constraint_indices(m)
    [
        (unit=u, node=n, direction=d, t=t)
        for (u, n, d) in indices(unit_capacity)
        for t in time_slice(
            m; temporal_block=vcat(node__temporal_block(node=n), units_on__temporal_block(unit=u))
        )
    ]
end
```
Here, we are concatenating the result of `node__temporal_block(...)` and `units_on__temporal_block(...)` using `vcat`,
and passing the result to `time_slice`. The final result, then, is the time-slices associated with either
the [unit](@ref) 'spatial' index `u`, the [node](@ref) 'spatial' index `n`, or both.

Let's check by re-running [the code that shows the constraints](@ref the_code_that_shows):

```julia
my_unit_flow_capacity(unit = pwrplant, node = elec, direction = to_node, t = 2023-01-01T00:00~>2023-01-01T01:00) : 0 ≤ 0
my_unit_flow_capacity(unit = pwrplant, node = elec, direction = to_node, t = 2023-01-01T00:00~>2023-01-01T02:00) : 0 ≤ 0
my_unit_flow_capacity(unit = pwrplant, node = elec, direction = to_node, t = 2023-01-01T01:00~>2023-01-01T02:00) : 0 ≤ 0
my_unit_flow_capacity(unit = pwrplant, node = elec, direction = to_node, t = 2023-01-01T02:00~>2023-01-01T03:00) : 0 ≤ 0
my_unit_flow_capacity(unit = pwrplant, node = elec, direction = to_node, t = 2023-01-01T02:00~>2023-01-01T04:00) : 0 ≤ 0
my_unit_flow_capacity(unit = pwrplant, node = elec, direction = to_node, t = 2023-01-01T03:00~>2023-01-01T04:00) : 0 ≤ 0
my_unit_flow_capacity(unit = pwrplant, node = elec, direction = to_node, t = 2023-01-01T04:00~>2023-01-01T05:00) : 0 ≤ 0
my_unit_flow_capacity(unit = pwrplant, node = elec, direction = to_node, t = 2023-01-01T04:00~>2023-01-01T06:00) : 0 ≤ 0
my_unit_flow_capacity(unit = pwrplant, node = elec, direction = to_node, t = 2023-01-01T05:00~>2023-01-01T06:00) : 0 ≤ 0
my_unit_flow_capacity(unit = pwrplant, node = elec, direction = to_node, t = 2023-01-01T06:00~>2023-01-01T07:00) : 0 ≤ 0
my_unit_flow_capacity(unit = pwrplant, node = elec, direction = to_node, t = 2023-01-01T07:00~>2023-01-01T08:00) : 0 ≤ 0
my_unit_flow_capacity(unit = pwrplant, node = elec, direction = to_node, t = 2023-01-01T08:00~>2023-01-01T09:00) : 0 ≤ 0
my_unit_flow_capacity(unit = pwrplant, node = fuel, direction = from_node, t = 2023-01-01T00:00~>2023-01-01T02:00) : 0 ≤ 0
my_unit_flow_capacity(unit = pwrplant, node = fuel, direction = from_node, t = 2023-01-01T00:00~>2023-01-01T03:00) : 0 ≤ 0
my_unit_flow_capacity(unit = pwrplant, node = fuel, direction = from_node, t = 2023-01-01T02:00~>2023-01-01T04:00) : 0 ≤ 0
my_unit_flow_capacity(unit = pwrplant, node = fuel, direction = from_node, t = 2023-01-01T03:00~>2023-01-01T06:00) : 0 ≤ 0
my_unit_flow_capacity(unit = pwrplant, node = fuel, direction = from_node, t = 2023-01-01T04:00~>2023-01-01T06:00) : 0 ≤ 0
```

Now we are getting a lot of time-slices! On the `elec` side, we get both time-slices at one- and two-hour
resolution. On the `fuel` side, we get both at two- and three-. We shouldn't be applying the constraint more
than once for the same period of time, for efficiency - so we should just take the ones with the *highest*
resolution.

Let's try again:
```julia
function my_unit_flow_capacity_constraint_indices(m)
    [
        (unit=u, node=n, direction=d, t=t)
        for (u, n, d) in indices(unit_capacity)
        for t in t_highest_resolution(
            time_slice(
                m; temporal_block=vcat(node__temporal_block(node=n), units_on__temporal_block(unit=u))
            )
        )
    ]
end
```
Here we are using a function from SpineInterface called `t_highest_resolution`. This function takes an
`Array` of time-slices and returns another `Array` only with the ones that don't contain any other - i.e.,
the ones with the highest resolution.

Let's see what we get by running [the code that shows the constraints](@ref the_code_that_shows):

```julia
my_unit_flow_capacity(unit = pwrplant, node = elec, direction = to_node, t = 2023-01-01T00:00~>2023-01-01T01:00) : 0 ≤ 0
my_unit_flow_capacity(unit = pwrplant, node = elec, direction = to_node, t = 2023-01-01T01:00~>2023-01-01T02:00) : 0 ≤ 0
my_unit_flow_capacity(unit = pwrplant, node = elec, direction = to_node, t = 2023-01-01T02:00~>2023-01-01T03:00) : 0 ≤ 0
my_unit_flow_capacity(unit = pwrplant, node = elec, direction = to_node, t = 2023-01-01T03:00~>2023-01-01T04:00) : 0 ≤ 0
my_unit_flow_capacity(unit = pwrplant, node = elec, direction = to_node, t = 2023-01-01T04:00~>2023-01-01T05:00) : 0 ≤ 0
my_unit_flow_capacity(unit = pwrplant, node = elec, direction = to_node, t = 2023-01-01T05:00~>2023-01-01T06:00) : 0 ≤ 0
my_unit_flow_capacity(unit = pwrplant, node = elec, direction = to_node, t = 2023-01-01T06:00~>2023-01-01T07:00) : 0 ≤ 0
my_unit_flow_capacity(unit = pwrplant, node = elec, direction = to_node, t = 2023-01-01T07:00~>2023-01-01T08:00) : 0 ≤ 0
my_unit_flow_capacity(unit = pwrplant, node = elec, direction = to_node, t = 2023-01-01T08:00~>2023-01-01T09:00) : 0 ≤ 0
my_unit_flow_capacity(unit = pwrplant, node = fuel, direction = from_node, t = 2023-01-01T00:00~>2023-01-01T02:00) : 0 ≤ 0
my_unit_flow_capacity(unit = pwrplant, node = fuel, direction = from_node, t = 2023-01-01T02:00~>2023-01-01T04:00) : 0 ≤ 0
my_unit_flow_capacity(unit = pwrplant, node = fuel, direction = from_node, t = 2023-01-01T04:00~>2023-01-01T06:00) : 0 ≤ 0
```

Ah, that looks a lot better! We are getting one-hour on the `elec` side, and two-hour on the `fuel` side.
I'm pretty sure that's exactly what we want!

So we have found the *current* time-slice - now let's find the *next* one.

For this we will use a special function from SpineOpt called `t_before_t`.
This function is mainly intended to be called while specifying one of its two keyword arguments,
`t_before` or `t_after`, with some time-slice.
- If you specify `t_before`, you get all the time-slices that *start* when the given time-slice *ends*.
- If you specify `t_after`, you get all the time-slices that *end* when the given one *starts*.

!!! note
    You might be asking yourself, how could there be more than one time-slice starting when another one ends,
    or ending when another one starts?
    Well, simply because in SpineOpt we can have multiple [temporal\_block](@ref)s defined over the same period
    of time, with different resolutions - so time-slices of those blocks will simply overlap.
    Therefore, there might be multiple time-slices starting at the same time, and also multiple ones ending at
    the same time.

So let's use `t_before_t` to try and compute the *next* time-slices for our constraint.
We know that the *next* time-slice should come from the same set as the *current*, that is,
the highest-resolution time-slices associated to the [unit](@ref) and/or the [node](@ref).
But the *next* should also come *after* the *current*. So basically we can try something like this:

```julia
function my_unit_flow_capacity_constraint_indices(m)
    [
        (unit=u, node=n, direction=d, t=t, t_next=t_next)
        for (u, n, d) in indices(unit_capacity)
        for t in t_highest_resolution(
            time_slice(
                m; temporal_block=vcat(node__temporal_block(node=n), units_on__temporal_block(unit=u))
            )
        )
        for t_next in t_highest_resolution(
            time_slice(
                m;
                temporal_block=vcat(node__temporal_block(node=n), units_on__temporal_block(unit=u)),
                t=t_before_t(m; t_before=t),
            )
        )
    ]
end
```

Let's unpack the last call to `time_slice` above (the one that we iterate to obtain `t_next`).
Basically, we're doing almost exactly the same as we do to obtain the current time-slice, `t` 
(that is, calling `time_slice` by specifying the `temporal_block` argument so we only get
time-slices associated to our [unit](@ref) `u` and/or our [node](@ref) `n`).
Except that on top of that, we are also specifying the `t` argument so we only get time-slices that start
when our current 'temporal' index `t` ends - as obtained with `t_before_t`.

This should work, right? Well, let's run [the code that shows the constraints](@ref the_code_that_shows) again to see
what happens:

```julia
my_unit_flow_capacity(unit = pwrplant, node = elec, direction = to_node, t = 2023-01-01T00:00~>2023-01-01T01:00, t_next = 2023-01-01T01:00~>2023-01-01T02:00) : 0 ≤ 0
my_unit_flow_capacity(unit = pwrplant, node = elec, direction = to_node, t = 2023-01-01T01:00~>2023-01-01T02:00, t_next = 2023-01-01T02:00~>2023-01-01T03:00) : 0 ≤ 0
my_unit_flow_capacity(unit = pwrplant, node = elec, direction = to_node, t = 2023-01-01T02:00~>2023-01-01T03:00, t_next = 2023-01-01T03:00~>2023-01-01T04:00) : 0 ≤ 0
my_unit_flow_capacity(unit = pwrplant, node = elec, direction = to_node, t = 2023-01-01T03:00~>2023-01-01T04:00, t_next = 2023-01-01T04:00~>2023-01-01T05:00) : 0 ≤ 0
my_unit_flow_capacity(unit = pwrplant, node = elec, direction = to_node, t = 2023-01-01T04:00~>2023-01-01T05:00, t_next = 2023-01-01T05:00~>2023-01-01T06:00) : 0 ≤ 0
my_unit_flow_capacity(unit = pwrplant, node = elec, direction = to_node, t = 2023-01-01T05:00~>2023-01-01T06:00, t_next = 2023-01-01T06:00~>2023-01-01T07:00) : 0 ≤ 0
my_unit_flow_capacity(unit = pwrplant, node = elec, direction = to_node, t = 2023-01-01T06:00~>2023-01-01T07:00, t_next = 2023-01-01T07:00~>2023-01-01T08:00) : 0 ≤ 0
my_unit_flow_capacity(unit = pwrplant, node = elec, direction = to_node, t = 2023-01-01T07:00~>2023-01-01T08:00, t_next = 2023-01-01T08:00~>2023-01-01T09:00) : 0 ≤ 0
my_unit_flow_capacity(unit = pwrplant, node = fuel, direction = from_node, t = 2023-01-01T00:00~>2023-01-01T02:00, t_next = 2023-01-01T02:00~>2023-01-01T04:00) : 0 ≤ 0
my_unit_flow_capacity(unit = pwrplant, node = fuel, direction = from_node, t = 2023-01-01T02:00~>2023-01-01T04:00, t_next = 2023-01-01T04:00~>2023-01-01T06:00) : 0 ≤ 0
```
Beautiful. It looks like we have found our 'temporal' indices.

!!! note
    Have we? Well, almost. You may have noticed that after adding the `t_next` component, we end up having fewer
    indices in total. Indeed, we are now missing the ones where `t` (the *current* time slice) was
    `2023-01-01T08:00~>2023-01-01T09:00` and `2023-01-01T04:00~>2023-01-01T06:00`. Why is that?
    Well, simply because at `2023-01-01T09:00` the `1hourly` block ends, and at `2023-01-01T06:00` the model ends -
    so there are no time-slices after that.
    In this case, `t_before_t` just returns an empty array and `my_unit_flow_capacity_constraint_indices` 
    doesn't find any `t_next` to iterate over.
    We should remediate this, but we won't do it immediately. We will save it for the very last,
    because it really doesn't stop us from progressing and might be a little bit distracting to do right now.
    Trust me, we will figure it out.

##### Stochastics

On to compute our 'stochastic' indices.

We said above that each of these indices will be a path in the stochastic scenario DAG associated
to our 'spatial' indices, that covers the time-slices from our 'temporal' indices.

Ok, so how do we find the paths? We will be using a convenience function from SpineOpt called
`active_stochastic_paths`.
The method we will use receives a model object `m` and two mandatory keyword arguments, `stochastic_structure` and `t`,
the former expecting a [stochastic\_structure](@ref) or `Array` of [stochastic\_structure](@ref)s,
and the latter a time-slice or `Array` of time-slices.
The method returns all the stochastic paths in the [stochastic\_scenario](@ref) DAG subsets corresponding to the given
[stochastic\_structure](@ref)s, where the given time slices exist.
We can use it as follows:

```
function my_unit_flow_capacity_constraint_indices(m)
    [
        (unit=u, node=n, direction=d, t=t, t_next=t_next, s_path=s_path)
        for (u, n, d) in indices(unit_capacity)
        for t in t_highest_resolution(
            time_slice(
                m; temporal_block=vcat(node__temporal_block(node=n), units_on__temporal_block(unit=u))
            )
        )
        for t_next in t_highest_resolution(
            time_slice(
                m;
                temporal_block=vcat(node__temporal_block(node=n), units_on__temporal_block(unit=u)),
                t=t_before_t(m; t_before=t),
            )
        )
        for s_path in active_stochastic_paths(
            m,
            stochastic_structure=vcat(
                node__stochastic_structure(node=n), units_on__stochastic_structure(unit=u)
            ),
            t=[t, t_next]
        )
    ]
end
```

And if we run [the code that shows the constraints](@ref the_code_that_shows), we get:

```julia
my_unit_flow_capacity(unit = pwrplant, node = elec, direction = to_node, t = 2023-01-01T00:00~>2023-01-01T01:00, t_next = 2023-01-01T01:00~>2023-01-01T02:00, s_path = Object[realisation]) : 0 = 0
my_unit_flow_capacity(unit = pwrplant, node = elec, direction = to_node, t = 2023-01-01T01:00~>2023-01-01T02:00, t_next = 2023-01-01T02:00~>2023-01-01T03:00, s_path = Object[realisation]) : 0 = 0
my_unit_flow_capacity(unit = pwrplant, node = elec, direction = to_node, t = 2023-01-01T02:00~>2023-01-01T03:00, t_next = 2023-01-01T03:00~>2023-01-01T04:00, s_path = Object[realisation]) : 0 = 0
my_unit_flow_capacity(unit = pwrplant, node = elec, direction = to_node, t = 2023-01-01T03:00~>2023-01-01T04:00, t_next = 2023-01-01T04:00~>2023-01-01T05:00, s_path = Object[realisation]) : 0 = 0
my_unit_flow_capacity(unit = pwrplant, node = elec, direction = to_node, t = 2023-01-01T04:00~>2023-01-01T05:00, t_next = 2023-01-01T05:00~>2023-01-01T06:00, s_path = Object[realisation]) : 0 = 0
my_unit_flow_capacity(unit = pwrplant, node = elec, direction = to_node, t = 2023-01-01T05:00~>2023-01-01T06:00, t_next = 2023-01-01T06:00~>2023-01-01T07:00, s_path = Object[realisation, forecast1]) : 0 = 0
my_unit_flow_capacity(unit = pwrplant, node = elec, direction = to_node, t = 2023-01-01T05:00~>2023-01-01T06:00, t_next = 2023-01-01T06:00~>2023-01-01T07:00, s_path = Object[realisation, forecast2]) : 0 = 0
my_unit_flow_capacity(unit = pwrplant, node = elec, direction = to_node, t = 2023-01-01T06:00~>2023-01-01T07:00, t_next = 2023-01-01T07:00~>2023-01-01T08:00, s_path = Object[realisation, forecast1]) : 0 = 0
my_unit_flow_capacity(unit = pwrplant, node = elec, direction = to_node, t = 2023-01-01T06:00~>2023-01-01T07:00, t_next = 2023-01-01T07:00~>2023-01-01T08:00, s_path = Object[realisation, forecast2]) : 0 = 0
my_unit_flow_capacity(unit = pwrplant, node = elec, direction = to_node, t = 2023-01-01T07:00~>2023-01-01T08:00, t_next = 2023-01-01T08:00~>2023-01-01T09:00, s_path = Object[realisation, forecast1]) : 0 = 0
my_unit_flow_capacity(unit = pwrplant, node = elec, direction = to_node, t = 2023-01-01T07:00~>2023-01-01T08:00, t_next = 2023-01-01T08:00~>2023-01-01T09:00, s_path = Object[realisation, forecast2]) : 0 = 0
my_unit_flow_capacity(unit = pwrplant, node = fuel, direction = from_node, t = 2023-01-01T00:00~>2023-01-01T02:00, t_next = 2023-01-01T02:00~>2023-01-01T04:00, s_path = Object[realisation]) : 0 = 0
my_unit_flow_capacity(unit = pwrplant, node = fuel, direction = from_node, t = 2023-01-01T02:00~>2023-01-01T04:00, t_next = 2023-01-01T04:00~>2023-01-01T06:00, s_path = Object[realisation]) : 0 = 0

```

Which looks like we're on to something.
Indeed, on the `fuel` side, `s_path` is always just `[realisation]`, because both the `fuel` [node](@ref)
and the `pwrplant` [unit](@ref) have the `one_stage` [stochastic\_structure](@ref).
But on the `elec` side, at the beginning we have `[realisation]` and then we start getting `[realisation, forecast1]`
and `[realisation, forecast2]`.
The turning point is exactly at `2023-01-01T06:00`, where `realisation` ends according to
the [stochastic\_scenario\_end](@ref) parameter.

So it's all good!

#### The function that generates the constraint

Congratulations, you have made it this far. Now we will finally start writing our constraint expression.

!!! note
    I will grab a coffee and be right back.



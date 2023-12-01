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
(And also, it looks like we also assume that a unit cannot start up and shut down in the same period.)

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
2. for each of those times, how far in time do we need to look.

To answer the first question, the first step is to understand where the different variables involved
in your constraint get their temporal resolution from. In our case, we have [unit\_flow](@ref),
[units\_on](@ref) and [units\_shut\_down](@ref). The former gets its resolution from the associated [node](@ref),
via [node\_\_temporal\_block](@ref); whereas the two latter get it from the [unit](@ref),
via [units\_on\_\_temporal\_block](@ref).

If all [node](@ref)s and [unit](@ref)s had the same temporal resolution, there would be no questions to ask.
We'd just take that unique resolution and that would give us our 'temporal' indices.
But since each [unit](@ref) and [node](@ref) is allowed to have their
own temporal resolutions (that's right, *resolutions* in plural), there are several questions to be asked:
What happens if, e.g., the [unit](@ref) has higher resolution than the [node](@ref) (or vice versa)?
What happens if the [unit](@ref) and/or the [node](@ref) have multiple resolutions running in parallel?
What happens if their resolutions change over time?

Ultimately, the question we need to answer is what is the 'lowest-resolution way' in which we can combine
the individual resolutions of all our 'spatial' indices so we never violate the constraint.
In our case, we need to guarantee that the flow between a [unit](@ref) and a [node](@ref)
is *never* higher than the [unit\_capacity](@ref). So it looks like we should be taking the *highest* resolution
of the [unit\_flow](@ref) variable.
But we also need to guarantee that the flow is lower than the [unit\_capacity](@ref) times the
[shut\_down\_limit](@ref) if the [unit](@ref) is shutting down in the next period. How does that affect the
resolution of the constraint? Is it still Ok to use the resolution of [unit\_flow](@ref)?
What happens if [units\_on](@ref) has higher resolution than [unit\_flow](@ref)?
Would we violate this part of the constraint in certain cases?

In doubt, something that could work is to take the highest resolution of all the individual resolutions
involved. That should ensure that we don't miss any time-slice, but at the same time it might not be
the most efficient...

Now, to answer the second question, we just need to look at our constraint expression.
In our case, we need to look at the current time-step, but also at the *next* time-step to check if the
unit is shutting down in that time step.
So our 'temporal' indices will be tuples of (current time-slice, next time-slice).

#### Collect the 'stochastic' indices

Here you need to answer the question, what are all the possible ways
of traversing the scenario graph while visiting all the time-slices in my 'temporal' indices
(determined above)?
Each of these traversals will be a 'stochastic' index for your constraint.
We call such a traversal a 'stochastic path',
and it's essentially and array of [stochastic\_scenario](@ref)s. Check the [Stochastic Framework](@ref) section
for details.

So this is not that hard actually. We have the 'temporal' indices already,
and SpineOpt provides a convenience function to derive the stochastic paths given a set of time-slices.
So all we need to do is call this function. Handy, huh?


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
For example, 'give me all the [unit\_flow](@ref) indices
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
I guess what I meant is I don't want to do too much thinking - I want to see the results of what I'm doing
as I do it.

So for this I need a test system that triggers the creation of the constraint, is complex enough so I don't miss
any relevant cases, but not that complex that I'm unable to diagnose it.
In our case, I believe something like the below could work:

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
        ("stochastic_scenario", "first"),
        ("stochastic_scenario", "second"),
        ("stochastic_structure", "one_stage"),
        ("stochastic_structure", "two_stage"),
        ("unit", "power_plant"),
        ("node", "fuel"),
        ("node", "electricity"),
    ],
    relationships=[
        ("parent_stochastic_scenario__child_stochastic_scenario", ("first", "second")),
        ("stochastic_structure__stochastic_scenario", ("one_stage", "first")),
        ("stochastic_structure__stochastic_scenario", ("two_stage", "first")),
        ("stochastic_structure__stochastic_scenario", ("two_stage", "second")),
        ("unit__from_node", ("power_plant", "fuel")),
        ("unit__to_node", ("power_plant", "electricity")),
        ("node__temporal_block", ("fuel", "3hourly")),
        ("node__temporal_block", ("electricity", "hourly")),
        ("units_on__temporal_block", ("power_plant", "2hourly")),
        ("node__stochastic_structure", ("fuel", "one_stage")),
        ("node__stochastic_structure", ("electricity", "two_stage")),
        ("units_on__stochastic_structure", ("power_plant", "one_stage")),
    ],
    object_parameter_values=[
        ("model", "simple", "model_start", unparse_db_value(DateTime("2023-01-01T00:00"))),
        ("model", "simple", "model_end", unparse_db_value(DateTime("2023-01-01T06:00"))),
        ("temporal_block", "hourly", "resolution", unparse_db_value(Hour(1))),
        ("temporal_block", "2hourly", "resolution", unparse_db_value(Hour(2))),
        ("temporal_block", "3hourly", "resolution", unparse_db_value(Hour(3))),
    ],
    relationship_parameter_values=[
        (
            "stochastic_structure__stochastic_scenario",
            ("two_stage", "first"),
            "stochastic_scenario_end",
            unparse_db_value(Hour(6))
        ),
        ("unit__from_node", ("power_plant", "fuel"), "unit_capacity", 200),
        ("unit__to_node", ("power_plant", "electricity"), "unit_capacity", 100),
        ("unit__to_node", ("power_plant", "electricity"), "shut_down_limit", 0.2),
    ],
)
```

Whoa, what's all that stuff!?

Basically, what we're doing here is creating a SpineOpt [model](@ref) called `simple`, starting January first 2023
at 00:00 and ending at 06:00. This `simple` [model](@ref) has three [temporal\_block](@ref)s,
`1hourly`, `2hourly` and `3hourly`,
with one-, two-, and three-hour resolution respectively. It also has two [stochastic\_scenario](@ref)s,
`first` and `second`, where `first` comes before `second`; and two [stochastic\_structure](@ref)s, `one_stage`,
including only `first`, and `two_stage`, including both `first` and `second` and with `first` ending after 6 hours.

The [model](@ref) consists of two [node](@ref)s, `fuel` and `electricity`, with a [unit](@ref) in between,
`power_plant`. The `fuel` [node](@ref) is modelled at three-hour resolution and one-stage stochastics;
the `electricity` [node](@ref) is modelled at one-hour resolution and two-stage stochastics;
and the `power_plant` [unit](@ref) is modelled at two-hour resolution and one-stage stochastics.
Finally, the [unit\_capacity](@ref) is 200 for flows coming to the `power_plant` from the `fuel` [node](@ref),
and 300 for flows going from the `power_plant` to the `electricity` [node](@ref);
the [shut\_down\_limit](@ref) is 0.2 for the `electricity` [node](@ref) flows
(and none, thus irrestricted, for the `fuel` [node](@ref) flows).

!!! note
    If you have trouble understanding the above, maybe (unfortunately) it means you're not quite ready yet
    to write your own constraints in SpineOpt.
    My suggestion would be to go through the different tutorials and come back after that.

### The actual constraint code

I feel it's about time we finally start writing our constraint.
We will split our code in two functions:

- A function that receives a SpineOpt model object `m` and returns an `Array` containing all the constraint indices.
- A function that receives a SpineOpt model object `m` and adds the constraint to it.

Let's start with dummy versions of these functions so we can appreciate the infrastructure:


```julia
using JuMP

function my_unit_flow_capacity_constraint_indices(m)
    []
end

function add_my_unit_flow_capacity_constraint!(m)
    m.ext[:spineopt].constraints[:my_unit_flow_capacity] = Dict(
        ind => @constraint(m, 0 == 0)
        for ind in my_unit_flow_capacity_constraint_indices(m)
    )
end
```

The `my_unit_flow_capacity_constraint_indices` is at the moment returning no indices.
Then, for each of those indices (!), `add_my_unit_flow_capacity_constraint` is creating the constraint `0 == 0`
and adding it to the model. So yeah, not very useful, but probably good enough to get started.

!!! note
    In `add_my_unit_flow_capacity_constraint!`, the part that adds the constraint to the model is just the
    `@constraint(m, ...)` bit. The rest of the machinery is mainly for inspection purposes.
    We build a dictionary that maps each constraint index to
    the corresponding constraint, and store that dictionary in a specific location within the `m.ext` dictionary.
    Whit this we can easily access the generated constraints via the model object `m` that gets returned
    by `run_spineopt`.

#### The constraint indices function

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
        if unit_capacity(unit=u, node=n, direction=d) !== nothing
    ]
end
```
That should work.

!!! note
    We use the `!==` operator to compare 'identity' rather than 'values'.
    This is a Julia detail - maybe you're not that interested. Anyways, both `!==` and `!=` will work;
    `!==` is just considered 'more correct'.

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
Basically this argument takes a function that gets called with the model object
as part of the process of adding constraints. So if we call `run_spineopt` while passing
the `add_my_unit_flow_capacity_constraint!` function via the `add_constraints` argument, our constraint will
be added to the model:

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
Note that we are also passing `nothing` as the second argument (the output URL) to `run_spineopt`,
because we don't want to write results.
In fact, we don't even want to solve (`optimize=false`), we are just interested in inspecting our constraint.
We also aren't very interested in the log (`log_level=0`).

And after that, we are just printing all the constraints that got generated ordered by index.
At the moment it should be printing:

```
my_unit_flow_capacity(unit = power_plant, node = fuel, direction = from_node) : 0 = 0
my_unit_flow_capacity(unit = power_plant, node = electricity, direction = to_node) : 0 = 0
```

which (believe it or not) means it's working.

##### Time

Let's add the 'temporal' indices. We know that we need two of such indices: the *current* time-slice,
and the *next* time-slice. Let's start with the current one.

We know we need to combine the time-slices of all our 'spatial' indices in a way, so we don't violate the constraint
at any period in time.
Let's start simple. Let's begin by taking only the time-slices associated to the [unit](@ref):

```julia
function my_unit_flow_capacity_constraint_indices(m)
    [
        (unit=u, node=n, direction=d, t=t)
        for (u, n, d) in indices(unit_capacity)
        for t in time_slice(m; temporal_block=units_on__temporal_block(unit=u))
    ]
end
```

Note how we call `units_on__temporal_block` while passing our [unit](@ref) index via the `unit` argument.
This returns an `Array` with the [temporal\_block](@ref)s associated to the [unit](@ref).
Then we pass that `Array` to the `time_slice` function via the `temporal_block` argument,
to obtain all the associated time-slices.

If we rerun [the code that shows the constraints](@ref the_code_that_shows), we see the following:

```julia
my_unit_flow_capacity(unit = power_plant, node = electricity, direction = to_node, t = 2023-01-01T00:00~>2023-01-01T02:00) : 0 = 0
my_unit_flow_capacity(unit = power_plant, node = electricity, direction = to_node, t = 2023-01-01T02:00~>2023-01-01T04:00) : 0 = 0
my_unit_flow_capacity(unit = power_plant, node = electricity, direction = to_node, t = 2023-01-01T04:00~>2023-01-01T06:00) : 0 = 0
my_unit_flow_capacity(unit = power_plant, node = fuel, direction = from_node, t = 2023-01-01T00:00~>2023-01-01T02:00) : 0 = 0
my_unit_flow_capacity(unit = power_plant, node = fuel, direction = from_node, t = 2023-01-01T02:00~>2023-01-01T04:00) : 0 = 0
my_unit_flow_capacity(unit = power_plant, node = fuel, direction = from_node, t = 2023-01-01T04:00~>2023-01-01T06:00) : 0 = 0
```

So we are getting time-slices at two-hour resolution. This makes sense, because the `power_plant` [unit](@ref) is
associated to the `2hourly` [temporal\_block](@ref), remember? However, does it work?
Well, we know the `electricity` [node](@ref) is associated to the `1hourly` [temporal\_block](@ref),
and that means we have [unit\_flow](@ref) variables at one-hour resolution -
because [unit\_flow](@ref) gets its resolution from the [node](@ref), right?
We can't just enforce the constraint every two hours if the flows are tracked every hour!

So taking the time-slices of the [unit](@ref) is clearly insufficient, because we happen to have a [node](@ref)
at higher resolution.

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
my_unit_flow_capacity(unit = power_plant, node = electricity, direction = to_node, t = 2023-01-01T00:00~>2023-01-01T01:00) : 0 = 0
my_unit_flow_capacity(unit = power_plant, node = electricity, direction = to_node, t = 2023-01-01T01:00~>2023-01-01T02:00) : 0 = 0
my_unit_flow_capacity(unit = power_plant, node = electricity, direction = to_node, t = 2023-01-01T02:00~>2023-01-01T03:00) : 0 = 0
my_unit_flow_capacity(unit = power_plant, node = electricity, direction = to_node, t = 2023-01-01T03:00~>2023-01-01T04:00) : 0 = 0
my_unit_flow_capacity(unit = power_plant, node = electricity, direction = to_node, t = 2023-01-01T04:00~>2023-01-01T05:00) : 0 = 0
my_unit_flow_capacity(unit = power_plant, node = electricity, direction = to_node, t = 2023-01-01T05:00~>2023-01-01T06:00) : 0 = 0
my_unit_flow_capacity(unit = power_plant, node = fuel, direction = from_node, t = 2023-01-01T00:00~>2023-01-01T03:00) : 0 = 0
my_unit_flow_capacity(unit = power_plant, node = fuel, direction = from_node, t = 2023-01-01T03:00~>2023-01-01T06:00) : 0 = 0
```

So now we're getting time-slices at one-hour resolution on the `electricity` side, and three-hour on the `fuel` side.
This seems enough to enforce that the [unit\_flow](@ref) is never higher than the
[unit\_capacity](@ref).
However, we also need to enforce that the [unit\_flow](@ref) is never higher than the [unit\_capacity](@ref) times
the [shut\_down\_limit](@ref) if the unit is shutting down the next period.
Since the unit is able to shut-down 'at two-hour resolution', clearly taking the
three-hour resolution on the `fuel` side is insufficient to capture that situation.

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
Here, we are concatenating the result of `node__temporal_block(...)` and `units_on__temporal_block(...)`,
and using that to call `time_slice`. The result, then, is the time-slices associated with either the [unit](@ref)
or the [node](@ref).

Let's check by re-running [the code that shows the constraints](@ref the_code_that_shows):

```julia
my_unit_flow_capacity(unit = power_plant, node = electricity, direction = to_node, t = 2023-01-01T00:00~>2023-01-01T01:00) : 0 = 0
my_unit_flow_capacity(unit = power_plant, node = electricity, direction = to_node, t = 2023-01-01T00:00~>2023-01-01T02:00) : 0 = 0
my_unit_flow_capacity(unit = power_plant, node = electricity, direction = to_node, t = 2023-01-01T01:00~>2023-01-01T02:00) : 0 = 0
my_unit_flow_capacity(unit = power_plant, node = electricity, direction = to_node, t = 2023-01-01T02:00~>2023-01-01T03:00) : 0 = 0
my_unit_flow_capacity(unit = power_plant, node = electricity, direction = to_node, t = 2023-01-01T02:00~>2023-01-01T04:00) : 0 = 0
my_unit_flow_capacity(unit = power_plant, node = electricity, direction = to_node, t = 2023-01-01T03:00~>2023-01-01T04:00) : 0 = 0
my_unit_flow_capacity(unit = power_plant, node = electricity, direction = to_node, t = 2023-01-01T04:00~>2023-01-01T05:00) : 0 = 0
my_unit_flow_capacity(unit = power_plant, node = electricity, direction = to_node, t = 2023-01-01T04:00~>2023-01-01T06:00) : 0 = 0
my_unit_flow_capacity(unit = power_plant, node = electricity, direction = to_node, t = 2023-01-01T05:00~>2023-01-01T06:00) : 0 = 0
my_unit_flow_capacity(unit = power_plant, node = fuel, direction = from_node, t = 2023-01-01T00:00~>2023-01-01T02:00) : 0 = 0
my_unit_flow_capacity(unit = power_plant, node = fuel, direction = from_node, t = 2023-01-01T00:00~>2023-01-01T03:00) : 0 = 0
my_unit_flow_capacity(unit = power_plant, node = fuel, direction = from_node, t = 2023-01-01T02:00~>2023-01-01T04:00) : 0 = 0
my_unit_flow_capacity(unit = power_plant, node = fuel, direction = from_node, t = 2023-01-01T03:00~>2023-01-01T06:00) : 0 = 0
my_unit_flow_capacity(unit = power_plant, node = fuel, direction = from_node, t = 2023-01-01T04:00~>2023-01-01T06:00) : 0 = 0
```

Now we are getting a lot of time-slices! On the `electricity` side, we get both time-slices at one- and two-hour
resolution. On the `fuel` side, we get both at two- and three-. We shouldn't be applying the constraint more
than once for the same period of time, so for efficiency, we should just take the ones with the *highest*
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
my_unit_flow_capacity(unit = power_plant, node = electricity, direction = to_node, t = 2023-01-01T00:00~>2023-01-01T01:00) : 0 = 0
my_unit_flow_capacity(unit = power_plant, node = electricity, direction = to_node, t = 2023-01-01T01:00~>2023-01-01T02:00) : 0 = 0
my_unit_flow_capacity(unit = power_plant, node = electricity, direction = to_node, t = 2023-01-01T02:00~>2023-01-01T03:00) : 0 = 0
my_unit_flow_capacity(unit = power_plant, node = electricity, direction = to_node, t = 2023-01-01T03:00~>2023-01-01T04:00) : 0 = 0
my_unit_flow_capacity(unit = power_plant, node = electricity, direction = to_node, t = 2023-01-01T04:00~>2023-01-01T05:00) : 0 = 0
my_unit_flow_capacity(unit = power_plant, node = electricity, direction = to_node, t = 2023-01-01T05:00~>2023-01-01T06:00) : 0 = 0
my_unit_flow_capacity(unit = power_plant, node = fuel, direction = from_node, t = 2023-01-01T00:00~>2023-01-01T02:00) : 0 = 0
my_unit_flow_capacity(unit = power_plant, node = fuel, direction = from_node, t = 2023-01-01T02:00~>2023-01-01T04:00) : 0 = 0
my_unit_flow_capacity(unit = power_plant, node = fuel, direction = from_node, t = 2023-01-01T04:00~>2023-01-01T06:00) : 0 = 0
```

Ah, that looks a lot better! We are getting one-hour on the `electricity` side, and two-hour on the `fuel` side.
I believe that's exactly what we need!

##### Stochastics

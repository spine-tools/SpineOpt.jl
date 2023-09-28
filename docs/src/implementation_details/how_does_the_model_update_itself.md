# How does the model update itself after rolling?

In SpineOpt, constraints, objective and bounds update themselves automatically whenever the model rolls.
To picture this, imagine you have a rolling model with two windows,
corresponding to the first and second days of 2023, and daily resolution.
(In other words, each window consists of a single time-slice that covers the entire day.)
Also, imagine you have a `node` where the `demand` is a time-series defined as follows:

| timestamp | value |
| --- | --- |
|2023-01-01 | 5 |
|2023-01-02 | 10 |


To simplify things, let's say the nodal balance constraint in SpineOpt has the following form:

```
sum of flows entering the node - sum of flows leaving the node == node's demand
(for each t in the current window)
```

You would expect the rhs of this constraint to be 5 for the first window, and 10 for the second window.
That is indeed the case, but the way this works under the hood is quite 'magical' so to say.

In SpineOpt, the rhs of the above constraint would be written (roughly) using the following julia expression:

```julia
demand[(node=n, t=t, more arguments...)]
```

Notice the brackets (`[]`) around the named-tuple with the arguments.
Without these (i.e., `demand(node=n, t=t, more arguments...)`) the expression would evaluate to a number,
and the constraint would be static (non-self-updating).
But *with* the brackets, instead of a number, the expression evaluates to a special object of type `Call`.
The important thing about the `Call` is it remembers the arguments, including the `t`.

Right before the constraint is passed to the solver, SpineOpt 'realizes' the `Call` with the current value of `t`,
and computes the actual rhs. So for the first window, where `t` is the first day in 2023, it will be 5.

Now, whenever SpineOpt rolls forward to solve the next window,
it updates the value of `t` by adding the `roll_forward` value.
(This allows SpineOpt to reuse the same time-slices in all the windows.)
But when this happens, the `Call` is also checked to see if it would return something different
now that `t` has been rolled.
And if that's the case, the constraint is automatically updated to reflect the change.
In our example, the rhs would become 10 because `t` is now the second day.

In sum, without the brackets, the constraint would be `lhs == 5` (and it would never change),
whereas with the brackets, the constraint becomes
`lhs == the demand at the current value of t`.

And the above is valid not only for rhs, but also for any coefficient in any constraint or objective,
and for any variable bound.

To see how all this is actually implemented, we suggest you to look at the code of SpineInterface.
The starting point is the implementation of `Base.getindex` for the `Parameter` type so that writing, e.g.,
`demand[...arguments...]` returns a `Call` that remembers the arguments.
From then, we proceed to extend JuMP.jl to handle our `Call` objects within constraints and objective.
The last bit is perhaps the most complex, and consists in storing callbacks inside `TimeSlice` objects
whenever they are used to retrieve the value of a `Parameter` to build a model.
The callbacks are carefully crafted to update a specific part of that model
(e.g., a variable coefficient, a variable bound, a constraint rhs).
Whenever the `TimeSlice` rolls, depending on how much it rolls, the appropriate callbacks are called
resulting in the model being properly updated.
That's roughly it! Hopefully this brief introduction helps (but please contact us if you need more guidance).

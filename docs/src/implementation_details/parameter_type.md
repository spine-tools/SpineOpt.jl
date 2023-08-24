# Usage of 'parameter calls'

In SpineOpt, constraints, objective and bounds update themselves automatically whenever the model rolls.
To picture this, imagine you have a `node` where the `demand` is a time-series of the form `(day1 -> value1, day2 -> value2)`.
Now asume you also have specified `roll_forward` in such a way so that the first window corresponds to `day1`, and the second window corresponds to `day2`.
Also, to simplify things, let's say the nodal balance constraint in SpineOpt has the form:

```
sum of inflows minus sum of outflows during time t == node's demand at time t,
for each t in the current window
```

You would expect the rhs of this constraint to be `value1` for the first window, and `value2` for the second window.
That is indeed the case, but the way this works under the hood is quite 'magical' so to say.

In SpineOpt, the rhs of the above constraint would be written (roughly) using the following julia expression:

```julia
demand[(node=n, t=t, more arguments...)]
```

Note the brackets (`[]`) around the namedtuple containing the arguments.
Without these (i.e., `demand(node=n, t=t, more arguments...)`) the expression would return a number, and the constraint would be static (non-self-updating).
But *with* the brackets, instead of a number, the expression returns a special object of type `Call`.
The important thing about the `Call` is it remembers the `t` it was generated with.

Right before the constraint is passed to the solver, SpineOpt 'realizes' the `Call`
with the current value of `t`, and computes the actual rhs. So for the first window, where `t` is in `day1`, this will be `value1`.

Now, whenever SpineOpt rolls forward to solve the next window, it updates the value of `t` by adding the `roll_forward` value.
(This allows SpineOpt to reuse the same time-slices in all the windows.)
But when this happens, the `Call` is also checked to see if it would return something different now that `t` has been rolled.
And if that's the case, the constraint is automatically updated to reflect the change. In our example, the rsh would become `value2`
because `t` is now in `day2`.

In sum, without the brackets, the constraint would be `lhs == value1` (and it would never change), whereas with the brackets, the constraint becomes
`lhs == the value of the demand at the current value of t`.

And the above is valid not only for rhs, but also for any coefficient in any constraint or objective, and for any variable bound.

To see how all this is actually implemented, we suggest you to look at the code of SpineInterface.
The starting point is the implementation of `Base.getindex` for the `Parameter` type so that writing, e.g., `demand[...arguments...]` returns a `Call` that remembers the arguments.
From then, we proceed to implement `JuMP.build_constraint` and `JuMP.add_constraint` to handle our `Call` objects.
The last bit is the most complex, and consists in storing callbacks inside `TimeSlice` objects whenever they are used to call a `ParameterValue` to generate a model.
The callbacks are designed to update a specific part of that model (e.g., a variable coefficient, a variable bound, a constraint rhs).
Whenever the `TimeSlice` rolls, depending on how much it rolls, the appropriate callbacks are called resulting in the model being properly updated.
That's roughly it, hope this brief introduction helps (but we know this is not easy).

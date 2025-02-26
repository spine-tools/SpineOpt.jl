Connection: Duration parameter that determines the minimum duration of `connection` investment decisions. Once a `connection` has been invested-in, it must remain invested-in for `lifetime_technical`.

Unit: Duration parameter that determines the minimum duration of `unit` investment decisions. Once a `unit` has been invested-in, it must remain invested-in for `lifetime_technical`.

Note that `lifetime_technical` is a dynamic parameter that will impact the amount of solution history that must remain available to the optimisation in each step - this may impact performance.

See also [Investment Optimization](@ref) and [investment\_count\_max\_cumulative](@ref)

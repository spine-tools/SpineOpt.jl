If `true`, the results of every Benders iteration are written to the output database:
the master problem results (e.g. investments) and the sub problem results,
with an extra dimension `benders_iteration` (`bi_001`, `bi_002`, ...).
The `solution_stats` output then also lists the objective lower bound, upper bound and Benders gap
of every iteration.

If `false` (the default), results are only written once the Benders algorithm has finished,
and `solution_stats` only shows the final bounds and gap.

Useful for following how the investments and the gap develop over the iterations,
e.g. when choosing [decomposition\_max\_gap](@ref) or [decomposition\_max\_iterations](@ref).
Note that writing every iteration makes the output database larger.

See [Decomposition](@ref).

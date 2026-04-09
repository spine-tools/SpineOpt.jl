#############################################################################
# Copyright (C) 2017 - 2021 Spine project consortium
# Copyright SpineOpt contributors
#
# This file is part of SpineOpt.
#
# SpineOpt is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# SpineOpt is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#############################################################################

@doc raw"""
Constrain the variable [storages\_invested\_available](@ref) by the investment lifetime of a storage.
The parameter [storage\_investment\_lifetime\_sense](@ref) defaults to minimum investment
lifetime ([storage\_investment\_lifetime\_sense](@ref) [`>=`](@ref constraint_sense_list)),
but can be changed to allow strict investment lifetime ([storage\_investment\_lifetime\_sense](@ref) [`==`](@ref constraint_sense_list))
or maximum investment lifetime ([storage\_investment\_lifetime\_sense](@ref) [`<=`](@ref constraint_sense_list)).
The storage lifetime is enforced by the following constraint:

```math
\begin{aligned}
& v^{storages\_invested\_available}_{(n,s,t)}
- \sum_{
        t\_past = t-p^{storage\_investment\_tech\_lifetime}
}^{t}
v^{storages\_invested}_{(n,s,t\_past)} \\
& \begin{cases}
\ge & \text{if } p^{storage\_investment\_lifetime\_sense} = ">=" \\
= & \text{if } p^{storage\_investment\_lifetime\_sense} = "==" \\
\le & \text{if } p^{storage\_investment\_lifetime\_sense} = "<=" \\
\end{cases} \\
& 0 \\
& \forall (n,s,t)
\end{aligned}
```
"""
function add_constraint_storage_lifetime!(m::Model)
    _add_constraint!(m, :storage_lifetime, constraint_storage_lifetime_indices, _build_constraint_storage_lifetime)
end

function _build_constraint_storage_lifetime(m::Model, n, s_path, t)
    @fetch storages_invested_available, storages_invested = m.ext[:spineopt].variables
    build_sense_constraint(
        sum(
            storages_invested_available[n, s, t]
            for (n, s, t) in storages_invested_available_indices(m; node=n, stochastic_scenario=s_path, t=t);
            init=0,
        )
        -
        sum(
            storages_invested[n, s_past, t_past] * weight
            for (n, s_past, t_past, weight) in _past_storages_invested_available_indices(m, n, s_path, t)
        ),
        eval(storage_investment_lifetime_sense(node=n)),
        0
    )
end

function constraint_storage_lifetime_indices(m::Model)
    (
        (node=n, stochastic_path=path, t=t)
        for (n, t) in node_investment_time_indices(m; node=indices(storage_investment_tech_lifetime))
        for path in active_stochastic_paths(m, _past_storages_invested_available_indices(m, n, anything, t))
    )
end

function _past_storages_invested_available_indices(m, n, s_path, t)
    _past_indices(m, storages_invested_available_indices, storage_investment_tech_lifetime, s_path, t; node=n)
end

"""
    constraint_storage_lifetime_indices_filtered(m::Model; filtering_options...)

Form the stochastic indexing Array for the `:storages_invested_lifetime()` constraint.

Uses stochastic path indexing due to the potentially different stochastic structures between present and past time.
Keyword arguments can be used to filther the resulting Array.
"""
function constraint_storage_lifetime_indices_filtered(m::Model; node=anything, stochastic_path=anything, t=anything)
    f(ind) = _index_in(ind; node=node, stochastic_path=stochastic_path, t=t)
    filter(f, constraint_storage_lifetime_indices(m))
end
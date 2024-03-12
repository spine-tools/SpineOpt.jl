#############################################################################
# Copyright (C) 2017 - 2023  Spine Project
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
"""
    _find_children(parent_scenario::Union{Object,Anything})

The children of a `parent_scenario` as per the `parent_stochastic_scenario__child_stochastic_scenario` relationship.
"""
function _find_children(parent_scenario::Union{Object,Anything})
    parent_stochastic_scenario__child_stochastic_scenario(stochastic_scenario1=parent_scenario)
end

"""
    _find_root_scenarios(m::Model)

Find the `stochastic_scenario` objects without parents.
"""
_find_root_scenarios(m::Model) = _find_root_scenarios(m, anything)
function _find_root_scenarios(m::Model, stochastic_structure)
    all_scenarios = stochastic_structure__stochastic_scenario(stochastic_structure=stochastic_structure)
    setdiff(all_scenarios, _find_children(anything))
end

"""
    _stochastic_dag(m::Model, stochastic_structure::Object, window_start::DateTime, window_very_end::DateTime)

A `Dict` mapping `stochastic_scenario` objects to a `NamedTuple` of (start, end_, weight)
for the given `stochastic_structure`.

Aka dag, that is, a *realized* stochastic structure with all the parameter values in place.
"""
function _stochastic_dag(m::Model, stochastic_structure::Object, window_start::DateTime, window_very_end::DateTime)
    scenarios = _find_root_scenarios(m, stochastic_structure)
    scen_start = Dict(scen => window_start for scen in scenarios)
    scen_end = Dict()
    scen_weight = Dict(
        scen => Float64(weight_relative_to_parents(stochastic_structure=stochastic_structure, stochastic_scenario=scen))
        for scen in scenarios
    )
    for scen in scenarios
        scenario_duration = stochastic_scenario_end(
            stochastic_structure=stochastic_structure,
            stochastic_scenario=scen,
            _strict=false,
        )
        if scenario_duration === nothing
            scen_end[scen] = window_very_end
            continue
        end
        scen_end[scen] = scenario_end = window_start + scenario_duration
        children = _find_children(scen)
        children_relative_weight = Dict(
            child => weight_relative_to_parents(
                stochastic_structure=stochastic_structure,
                stochastic_scenario=child,
                _strict=false,
            ) for child in children
        )
        valid_children = [child for (child, weight) in children_relative_weight if weight !== nothing]
        invalid_children = setdiff(children, valid_children)
        if !isempty(invalid_children)
            @warn """
            prunning scenarios: $(join(invalid_children, ", ", " and ")), from $(stochastic_structure)'s dag, 
            since their value of `weight_relative_to_parents` is not specified
            """
        end
        for (child, child_relative_weight) in children_relative_weight
            scen_start[child] = haskey(scen_start, child) ? min(scen_start[child], scenario_end) : scenario_end
            scen_weight[child] = get(scen_weight, child, 0) + scen_weight[scen] * child_relative_weight
        end
        append!(scenarios, valid_children)
    end
    Dict(scen => (start=scen_start[scen], end_=scen_end[scen], weight=scen_weight[scen]) for scen in scenarios)
end

"""
    _all_stochastic_dags(m::Model)

A `Dict` mapping `stochastic_structure` objects to dags for the given `model`s.
"""
function _all_stochastic_dags(m::Model)
    window_start = start(current_window(m))
    window_very_end = end_(last(time_slice(m)))
    Dict(ss => _stochastic_dag(m, ss, window_start, window_very_end) for ss in stochastic_structure())
end

"""
    _time_slice_stochastic_scenarios(m::Model, stochastic_dag::Dict)

A `Dict` mapping `time_slice` objects to their set of active `stochastic_scenario` objects.
"""
function _time_slice_stochastic_scenarios(m::Model, stochastic_dag::Dict)
    # Window `time_slices`
    scenario_mapping = Dict(
        t => [scen for (scen, spec) in stochastic_dag if spec.start <= start(t) < spec.end_] for t in time_slice(m)
    )
    # History `time_slices`
    roots = _find_root_scenarios(m)
    history_scenario_mapping = Dict(t => roots for t in history_time_slice(m))
    merge!(scenario_mapping, history_scenario_mapping)
end

"""
    _generate_stochastic_scenarios(m::Model, all_stochastic_dags)

Generate a mapping from stochastic structure to time slice to scenarios.
"""
function _generate_stochastic_scenarios(m::Model, all_stochastic_dags)
    m.ext[:spineopt].stochastic_structure[:scenario_lookup] = Dict(
        (structure, t) => scens
        for (structure, dag) in all_stochastic_dags
        for (t, scens) in _time_slice_stochastic_scenarios(m, dag)
    )
end

function _stochastic_scenarios(m::Model, stoch_struct::Object, t::TimeSlice, scenarios)
    scenario_lookup = m.ext[:spineopt].stochastic_structure[:scenario_lookup]
    intersect(scenario_lookup[stoch_struct, t], scenarios)
end

"""
    _generate_any_stochastic_scenario_weight(m::Model, all_stochastic_dags::Dict)

Generate the `any_stochastic_scenario_weight` parameter for the `model` for easier access to the scenario weights.
"""
function _generate_any_stochastic_scenario_weight(m::Model, all_stochastic_dags::Dict)
    any_stochastic_scenario_weight_values = Dict(
        scen => Dict(:any_stochastic_scenario_weight => parameter_value(spec.weight))
        for ss in stochastic_structure()
        for (scen, spec) in all_stochastic_dags[ss]
    )
    add_object_parameter_values!(stochastic_scenario, any_stochastic_scenario_weight_values)
    m.ext[:spineopt].stochastic_structure[:any_stochastic_scenario_weight] = Parameter(
        :any_stochastic_scenario_weight, [stochastic_scenario]
    )
end

"""
    _generate_node_stochastic_scenario_weight(m::Model, all_stochastic_dags::Dict)

Generate the `node_stochastic_scenario_weight` parameter for the `model` for easier access to the scenario weights.
"""
function _generate_node_stochastic_scenario_weight(m::Model, all_stochastic_dags::Dict)
    node_stochastic_scenario_weight_values = Dict(
        (node, scen) => Dict(:node_stochastic_scenario_weight => parameter_value(spec.weight))
        for (node, ss) in Iterators.flatten((node__stochastic_structure(), node__investment_stochastic_structure()))
        for (scen, spec) in all_stochastic_dags[ss]
    )
    node__stochastic_scenario = RelationshipClass(
        :node__stochastic_scenario,
        [:node, :stochastic_scenario],
        keys(node_stochastic_scenario_weight_values),
        node_stochastic_scenario_weight_values,
    )
    m.ext[:spineopt].stochastic_structure[:node_stochastic_scenario_weight] = Parameter(
        :node_stochastic_scenario_weight, [node__stochastic_scenario]
    )
end

"""
    _generate_unit_stochastic_scenario_weight(all_stochastic_dags::Dict, m...)

Generate the `unit_stochastic_scenario_weight` parameter for the `model` for easier access to the scenario weights.
"""
function _generate_unit_stochastic_scenario_weight(m::Model, all_stochastic_dags::Dict)
    unit_stochastic_scenario_weight_values = Dict(
        (unit, scen) => Dict(:unit_stochastic_scenario_weight => parameter_value(param_vals.weight))
        for (unit, ss) in Iterators.flatten((units_on__stochastic_structure(), unit__investment_stochastic_structure()))
        for (scen, param_vals) in all_stochastic_dags[ss]
    )
    unit__stochastic_scenario = RelationshipClass(
        :unit__stochastic_scenario,
        [:unit, :stochastic_scenario],
        keys(unit_stochastic_scenario_weight_values),
        unit_stochastic_scenario_weight_values,
    )
    m.ext[:spineopt].stochastic_structure[:unit_stochastic_scenario_weight] = Parameter(
        :unit_stochastic_scenario_weight, [unit__stochastic_scenario]
    )
end

"""
    _generate_connection_stochastic_scenario_weight(all_stochastic_dags::Dict, m...)

Generate the `connection_stochastic_scenario_weight` parameter for the `model` for easier access to the scenario weights.
"""
function _generate_connection_stochastic_scenario_weight(m::Model, all_stochastic_dags::Dict)
    connection_stochastic_scenario_weight_values = Dict(
        (connection, scen) => Dict(:connection_stochastic_scenario_weight => parameter_value(param_vals.weight))
        for (connection, ss) in connection__investment_stochastic_structure()
        for (scen, param_vals) in all_stochastic_dags[ss]
    )
    connection__stochastic_scenario = RelationshipClass(
        :connection__stochastic_scenario,
        [:connection, :stochastic_scenario],
        keys(connection_stochastic_scenario_weight_values),
        connection_stochastic_scenario_weight_values,
    )
    m.ext[:spineopt].stochastic_structure[:connection_stochastic_scenario_weight] = Parameter(
        :connection_stochastic_scenario_weight, [connection__stochastic_scenario]
    )
end

"""
    _generate_active_stochastic_paths(m::Model)

Find all unique paths through the `parent_stochastic_scenario__child_stochastic_scenario` tree
and generate the `active_stochastic_paths` callable.
"""
function _generate_active_stochastic_paths(m::Model)
    paths = [[root] for root in _find_root_scenarios(m)]
    full_path_indices = []
    for (i, path) in enumerate(paths)
        children = _find_children(path[end])
        valid_children = setdiff(children, path)
        invalid_children = setdiff(children, valid_children)
        if !isempty(invalid_children)
            @warn """
            ignoring scenarios: $(join(invalid_children, ", ", " and ")), 
            as children of $(path[end]), since they're also its ancestors...
            """
        end
        isempty(valid_children) && push!(full_path_indices, i)
        append!(paths, [vcat(path, child) for child in valid_children])
    end
    # NOTE: `unique!` shouldn't be needed here since relationships are unique in the db.
    m.ext[:spineopt].stochastic_structure[:full_stochastic_paths] = paths[full_path_indices]
end

"""
    generate_stochastic_structure(m::Model)

Generate the stochastic structure for given SpineOpt model.

The stochastic structure is directed acyclic graph (DAG) where the vertices are the `stochastic_scenario` objects,
and the edges are given by the `parent_stochastic_scenario__child_stochastic_scenario` relationships.

After this, you can call `active_stochastic_paths` to slice the generated structure.
"""
function generate_stochastic_structure!(m::Model)
    all_stochastic_dags = _all_stochastic_dags(m)
    _generate_stochastic_scenarios(m, all_stochastic_dags)
    _generate_node_stochastic_scenario_weight(m, all_stochastic_dags)
    _generate_unit_stochastic_scenario_weight(m, all_stochastic_dags)
    _generate_connection_stochastic_scenario_weight(m, all_stochastic_dags)
    _generate_any_stochastic_scenario_weight(m, all_stochastic_dags)
    _generate_active_stochastic_paths(m)
end

"""
    active_stochastic_paths(m; stochastic_structure, t)

An `Array` where each element is itself an `Array` of `stochastic_scenario` `Object`s,
corresponding to a branch (or path) of the stochastic DAG associated to model `m`.
`stochastic_structure` can be either a single `Object` or `Vector` of `Object`s.
Similarly, `t` can be either a single `TimeSlice` or an `Array` of `TimeSlice`s.
The result is obtained by first taking the subset of the stochastic DAG associated to `stochastic_structure`,
and then taking the branches of that subset that cover `t`.
"""
function active_stochastic_paths(m; stochastic_structure, t)
    scenario_lookup = m.ext[:spineopt].stochastic_structure[:scenario_lookup]
    active_stochastic_paths(
        m,
        scen for ss in stochastic_structure for t_ in t for scen in scenario_lookup[ss, t_]
    )
end
function active_stochastic_paths(m, indices::Vector)
    active_stochastic_paths(m, (x.stochastic_scenario for x in indices))
end
function active_stochastic_paths(m, active_scenarios)
    active_stochastic_paths(m, collect(Object, active_scenarios))
end
function active_stochastic_paths(m, active_scenarios::Vector{Object})
    _active_stochastic_paths(m, unique!(active_scenarios))
end
function active_stochastic_paths(m, active_scenarios::Set{Object})
    _active_stochastic_paths(m, active_scenarios)
end

function _active_stochastic_paths(m, unique_active_scenarios)
    full_stochastic_paths = m.ext[:spineopt].stochastic_structure[:full_stochastic_paths]
    unique(intersect(path, unique_active_scenarios) for path in full_stochastic_paths)
end

function node_stochastic_indices(m::Model; node=anything, stochastic_scenario=anything)
    unique(
        (node=n, stochastic_scenario=s)
        for (n, ss) in node__stochastic_structure(node=node, _compact=false)
        for s in stochastic_structure__stochastic_scenario(stochastic_structure=ss)
    )
end

function unit_stochastic_indices(m::Model; unit=anything, stochastic_scenario=anything)
    unique(
        (unit=u, stochastic_scenario=s)
        for (u, ss) in units_on__stochastic_structure(unit=unit, _compact=false)
        for s in stochastic_structure__stochastic_scenario(stochastic_structure=ss)
    )
end

function stochastic_time_indices(
    m::Model;
    stochastic_scenario=anything,
    temporal_block=anything,
    t=anything,
)
    unique(
        (stochastic_scenario=s, t=t)
        for ss in stochastic_structure()
        for tb in intersect(SpineOpt.temporal_block(), temporal_block)
        for t in time_slice(m; temporal_block=members(tb), t=t)
        for s in _stochastic_scenarios(m, ss, t, stochastic_scenario)
    )
end

"""
    node_stochastic_time_indices(m;<keyword arguments>)

Stochastic time indexes for `nodes` with keyword arguments that allow filtering.
"""
function node_stochastic_time_indices(
    m::Model; node=anything, stochastic_scenario=anything, temporal_block=anything, t=anything
)
    unique(
        (node=n, stochastic_scenario=s, t=t)
        for (n, t) in node_time_indices(m; node=node, temporal_block=temporal_block, t=t)
        for ss in node__stochastic_structure(node=n)
        for s in _stochastic_scenarios(m, ss, t, stochastic_scenario)
    )
end

"""
    unit_stochastic_time_indices(;<keyword arguments>)

Stochastic time indexes for `units` with keyword arguments that allow filtering.
"""
function unit_stochastic_time_indices(
    m::Model;
    unit=anything,
    stochastic_scenario=anything,
    temporal_block=anything,
    t=anything,
)
    unique(
        (unit=u, stochastic_scenario=s, t=t)
        for (u, t) in unit_time_indices(m; unit=unit, temporal_block=temporal_block, t=t)
        for ss in units_on__stochastic_structure(unit=u)
        for s in _stochastic_scenarios(m, ss, t, stochastic_scenario)
    )
end

"""
    unit_investment_stochastic_time_indices(;<keyword arguments>)

Stochastic time indexes for `units_invested` with keyword arguments that allow filtering.
"""
function unit_investment_stochastic_time_indices(
    m::Model;
    unit=anything,
    stochastic_scenario=anything,
    temporal_block=anything,
    t=anything,
)
    unique(
        (unit=u, stochastic_scenario=s, t=t)
        for (u, t) in unit_investment_time_indices(m; unit=unit, temporal_block=temporal_block, t=t)
        for ss in unit__investment_stochastic_structure(unit=u)
        for s in _stochastic_scenarios(m, ss, t, stochastic_scenario)
    )
end

"""
    connection_investment_stochastic_time_indices(;<keyword arguments>)

Stochastic time indexes for `connections_invested` with keyword arguments that allow filtering.
"""
function connection_investment_stochastic_time_indices(
    m::Model;
    connection=anything,
    stochastic_scenario=anything,
    temporal_block=anything,
    t=anything,
)
    unique(
        (connection=conn, stochastic_scenario=s, t=t)
        for (conn, t) in connection_investment_time_indices(
            m; connection=connection, temporal_block=temporal_block, t=t,
        )
        for ss in connection__investment_stochastic_structure(connection=conn)
        for s in _stochastic_scenarios(m, ss, t, stochastic_scenario)
    )
end

"""
    node_investment_stochastic_time_indices(;<keyword arguments>)

Stochastic time indexes for `storages_invested` with keyword arguments that allow filtering.
"""
function node_investment_stochastic_time_indices(
    m::Model;
    node=anything,
    stochastic_scenario=anything,
    temporal_block=anything,
    t=anything,
)
    unique(
        (node=n, stochastic_scenario=s, t=t)
        for (n, t) in node_investment_time_indices(m; node=node, temporal_block=temporal_block, t=t)
        for ss in node__investment_stochastic_structure(node=n)
        for s in _stochastic_scenarios(m, ss, t, stochastic_scenario)
    )
end

function node_stochastic_scenario_weight(m; kwargs...)
    m.ext[:spineopt].stochastic_structure[:node_stochastic_scenario_weight][(; kwargs...)]
end

function unit_stochastic_scenario_weight(m; kwargs...)
    m.ext[:spineopt].stochastic_structure[:unit_stochastic_scenario_weight][(; kwargs...)]
end

function connection_stochastic_scenario_weight(m; kwargs...)
    m.ext[:spineopt].stochastic_structure[:connection_stochastic_scenario_weight][(; kwargs...)]
end

function any_stochastic_scenario_weight(m; kwargs...)
    m.ext[:spineopt].stochastic_structure[:any_stochastic_scenario_weight][(; kwargs...)]
end

#############################################################################
# Copyright (C) 2017 - 2018  Spine Project
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
    StochasticPathFinder

A callable type to retrieve intersections between valid stochastic paths
and 'active' scenarios.
"""
struct StochasticPathFinder
    full_stochastic_paths::Array{Array{Object,1},1}
end

struct StochasticScenarioSet
    scenarios::Dict{Object,Dict{TimeSlice,Array{Object}}}
end

"""
    active_stochastic_paths(active_scenarios::Union{Array{Object,1},Object})

Find the unique combinations of `active_scenarios` along valid stochastic paths.
"""
function (h::StochasticPathFinder)(active_scenarios::Union{Array{T,1},T}) where {T}
    # TODO: cache these
    unique(map(path -> intersect(path, active_scenarios), h.full_stochastic_paths))
end

function (h::StochasticScenarioSet)(structure::Object, t::TimeSlice, scenario)
    # TODO: cache these
    intersect(h.scenarios[structure][t], scenario)
end

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
function _find_root_scenarios(m::Model)
    all_scenarios = stochastic_structure__stochastic_scenario(
        stochastic_structure=model__stochastic_structure(model=m.ext[:instance]),
    )
    setdiff(all_scenarios, _find_children(anything))
end
function _find_root_scenarios(m::Model, stochastic_structure::Object)
    all_scenarios = stochastic_structure__stochastic_scenario(
        stochastic_structure=intersect(model__stochastic_structure(model=m.ext[:instance]), stochastic_structure),
    )
    setdiff(all_scenarios, _find_children(anything))
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
    full_stochastic_paths = paths[full_path_indices]
    active_stochastic_paths = StochasticPathFinder(full_stochastic_paths)
    @eval begin
        active_stochastic_paths = $active_stochastic_paths
    end
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
        scen => Float64(
            weight_relative_to_parents(stochastic_structure=stochastic_structure, stochastic_scenario=scen),
        ) for scen in scenarios
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
        scenario_end = window_start + scenario_duration
        scen_end[scen] = scenario_end
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
    Dict(
        structure => _stochastic_dag(m, structure, window_start, window_very_end)
        for structure in model__stochastic_structure(model=m.ext[:instance])
    )
end

"""
    _time_slice_stochastic_scenarios(m::Model, stochastic_dag::Dict)

A `Dict` mapping `time_slice` objects to their set of active `stochastic_scenario` objects.
"""
function _time_slice_stochastic_scenarios(m::Model, stochastic_dag::Dict)
    # Window `time_slices`
    scenario_mapping = Dict(
        t => [scen for (scen, param_vals) in stochastic_dag if param_vals.start <= start(t) < param_vals.end_]
        for t in time_slice(m)
    )
    # History `time_slices`
    roots = _find_root_scenarios(m)
    history_scenario_mapping = Dict(t => roots for t in history_time_slice(m))
    merge!(scenario_mapping, history_scenario_mapping)
end

"""
    _generate_stochastic_scenario_set(m::Model, all_stochastic_dags)

Generate the `_generate_stochastic_scenario_set` for all defined `stochastic_structures`.
"""
function _generate_stochastic_scenario_set(m::Model, all_stochastic_dags)
    m.ext[:stochastic_structure][:stochastic_scenario_set] = StochasticScenarioSet(
        Dict(structure => _time_slice_stochastic_scenarios(m, dag) for (structure, dag) in all_stochastic_dags),
    )
end

_stochastic_scenario_set(
    m::Model,
    structure::Object,
    t::TimeSlice,
    scenario,
) = m.ext[:stochastic_structure][:stochastic_scenario_set](structure, t, scenario)

"""
    node_stochastic_time_indices(m;<keyword arguments>)

Stochastic time indexes for `nodes` with keyword arguments that allow filtering.
"""
function node_stochastic_time_indices(
    m::Model;
    node=anything,
    stochastic_scenario=anything,
    temporal_block=anything,
    t=anything,
)
    unique(
        (node=n, stochastic_scenario=s, t=t1)
        for (n, t1) in node_time_indices(m; node=node, temporal_block=temporal_block, t=t)
        for (m_, structure) in model__stochastic_structure(
            model=m.ext[:instance],
            stochastic_structure=node__stochastic_structure(node=n),
            _compact=false,
        ) for s in _stochastic_scenario_set(m, structure, t1, stochastic_scenario)
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
        (unit=u, stochastic_scenario=s, t=t1)
        for (u, t1) in unit_time_indices(m; unit=unit, temporal_block=temporal_block, t=t)
        for (m_, structure) in model__stochastic_structure(
            model=m.ext[:instance],
            stochastic_structure=units_on__stochastic_structure(unit=u),
            _compact=false,
        ) for s in _stochastic_scenario_set(m, structure, t1, stochastic_scenario)
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
        (unit=u, stochastic_scenario=s, t=t1)
        for (u, t1) in unit_investment_time_indices(m; unit=unit, temporal_block=temporal_block, t=t)
        for (m_, structure) in model__stochastic_structure(
            model=m.ext[:instance],
            stochastic_structure=unit__investment_stochastic_structure(unit=u),
            _compact=false,
        ) for s in _stochastic_scenario_set(m, structure, t1, stochastic_scenario)
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
        (connection=conn, stochastic_scenario=s, t=t1) for (conn, t1) in connection_investment_time_indices(
            m;
            connection=connection,
            temporal_block=temporal_block,
            t=t,
        ) for structure in connection__investment_stochastic_structure(connection=conn)
            if structure in model__stochastic_structure(model=m.ext[:instance])
        for s in _stochastic_scenario_set(m, structure, t1, stochastic_scenario)
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
        (node=n, stochastic_scenario=s, t=t1)
        for (n, t1) in node_investment_time_indices(m; node=node, temporal_block=temporal_block, t=t)
        for (m_, structure) in model__stochastic_structure(
            model=m.ext[:instance],
            stochastic_structure=node__investment_stochastic_structure(node=n),
            _compact=false,
        ) for s in _stochastic_scenario_set(m, structure, t1, stochastic_scenario)
    )
end

"""
    _generate_node_stochastic_scenario_weight(m::Model, all_stochastic_dags::Dict)

Generate the `node_stochastic_scenario_weight` parameter for the `model` for easier access to the scenario weights.
"""
function _generate_node_stochastic_scenario_weight(m::Model, all_stochastic_dags::Dict)
    node_stochastic_scenario_weight_values = Dict(
        (node, scen) => Dict(:node_stochastic_scenario_weight => parameter_value(param_vals.weight))
        for (node, structure) in node__stochastic_structure()
            if structure in model__stochastic_structure(model=m.ext[:instance])
        for (scen, param_vals) in all_stochastic_dags[structure]
    )
    node__stochastic_scenario = RelationshipClass(
        :node__stochastic_scenario,
        [:node, :stochastic_scenario],
        [(node=n, stochastic_scenario=scen) for (n, scen) in keys(node_stochastic_scenario_weight_values)],
        node_stochastic_scenario_weight_values,
    )
    m.ext[:stochastic_structure][:node_stochastic_scenario_weight] = Parameter(
        :node_stochastic_scenario_weight,
        [node__stochastic_scenario],
    )
end

"""
    _generate_unit_stochastic_scenario_weight(all_stochastic_dags::Dict, m...)

Generate the `unit_stochastic_scenario_weight` parameter for the `model` for easier access to the scenario weights.
"""
function _generate_unit_stochastic_scenario_weight(m::Model, all_stochastic_dags::Dict)
    unit_stochastic_scenario_weight_values = Dict(
        (unit, scen) => Dict(:unit_stochastic_scenario_weight => parameter_value(param_vals.weight))
        for (unit, structure) in Iterators.flatten((
            units_on__stochastic_structure(),
            unit__investment_stochastic_structure(),
        )) if structure in model__stochastic_structure(model=m.ext[:instance])
        for (scen, param_vals) in all_stochastic_dags[structure]
    )
    unit__stochastic_scenario = RelationshipClass(
        :unit__stochastic_scenario,
        [:unit, :stochastic_scenario],
        [(unit=u, stochastic_scenario=scen) for (u, scen) in keys(unit_stochastic_scenario_weight_values)],
        unit_stochastic_scenario_weight_values,
    )
    m.ext[:stochastic_structure][:unit_stochastic_scenario_weight] = Parameter(
        :unit_stochastic_scenario_weight,
        [unit__stochastic_scenario],
    )
end

"""
    _generate_connection_stochastic_scenario_weight(all_stochastic_dags::Dict, m...)

Generate the `connection_stochastic_scenario_weight` parameter for the `model` for easier access to the scenario weights.
"""
function _generate_connection_stochastic_scenario_weight(m::Model, all_stochastic_dags::Dict)
    connection_stochastic_scenario_weight_values = Dict(
        (connection, scen) => Dict(:connection_stochastic_scenario_weight => parameter_value(param_vals.weight))
        for (connection, structure) in connection__investment_stochastic_structure()
            if structure in model__stochastic_structure(model=m.ext[:instance])
        for (scen, param_vals) in all_stochastic_dags[structure]
    )
    connection__stochastic_scenario = RelationshipClass(
        :connection__stochastic_scenario,
        [:connection, :stochastic_scenario],
        [(connection=c, stochastic_scenario=scen) for (c, scen) in keys(connection_stochastic_scenario_weight_values)],
        connection_stochastic_scenario_weight_values,
    )
    m.ext[:stochastic_structure][:connection_stochastic_scenario_weight] = Parameter(
        :connection_stochastic_scenario_weight,
        [connection__stochastic_scenario],
    )
end

node_stochastic_scenario_weight(
    m;
    kwargs...,
) = m.ext[:stochastic_structure][:node_stochastic_scenario_weight][(; kwargs...)]
unit_stochastic_scenario_weight(
    m;
    kwargs...,
) = m.ext[:stochastic_structure][:unit_stochastic_scenario_weight][(; kwargs...)]
connection_stochastic_scenario_weight(
    m;
    kwargs...,
) = m.ext[:stochastic_structure][:connection_stochastic_scenario_weight][(; kwargs...)]

"""
    generate_master_stochastic_structure(m::Model)

Generate stochastic structure all models.
"""
function generate_stochastic_structure!(m::Model)
    m.ext[:stochastic_structure] = Dict()
    all_stochastic_dags = _all_stochastic_dags(m)
    _generate_stochastic_scenario_set(m, all_stochastic_dags)
    _generate_node_stochastic_scenario_weight(m, all_stochastic_dags)
    _generate_unit_stochastic_scenario_weight(m, all_stochastic_dags)
    _generate_connection_stochastic_scenario_weight(m, all_stochastic_dags)
    _generate_active_stochastic_paths(m)
end

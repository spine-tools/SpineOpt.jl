using BenchmarkTools
using Dates
using SpineInterface
using SpineOpt
using Graphs
using Random

const SUITE = BenchmarkGroup()

#=
# To run this:
#
# - activate this env
# - dev ../
# - instantiate
# - include("benchmarks.jl") 
# - results = run(SUITE, verbose=true)
=#

function local_load_test_data(url_in, test_data)
    data = Dict(Symbol(key) => value for (key, value) in SpineOpt.template())
    merge!(data, test_data)
    SpineInterface.close_connection(url_in)
    SpineInterface.open_connection(url_in)
    SpineInterface.import_data(url_in, "testing"; data...)
end

function create_meshed_network(nodes_to, n_count; max_num_connections=3)
    Random.seed!(1)
    g = SimpleGraph(n_count)
    added_edges = Set{Tuple{Int,Int}}()
    for start_node in 1:n_count
        potential_end_nodes = setdiff(1:n_count, start_node)
        num_connections = rand(1:min(max_num_connections, length(potential_end_nodes)))
        shuffle!(potential_end_nodes)
        end_nodes = potential_end_nodes[1:num_connections]
        for end_node in end_nodes
            edge = (min(start_node, end_node), max(start_node, end_node))
            if !in(edge, added_edges)
                add_edge!(g, start_node, end_node)
                push!(added_edges, edge)
            end
        end
    end
    conns = ["conn_$(src(e))_to_$(dst(e))" for e in edges(g)]
    conns_from = [nodes_to[src(e)] for e in edges(g)]
    conns_to = [nodes_to[dst(e)] for e in edges(g)]
    return conns, conns_from, conns_to
end

function setup(; number_of_weeks=1, n_count=50, add_meshed_network=true, add_investment=false, add_rolling=false)
    url_in = "sqlite://"
    file_path_out = "$(@__DIR__)/test_out.sqlite"
    url_out = "sqlite:///$file_path_out"
    t_count = 24 * 7 * number_of_weeks
    units = ["unit_$k" for k in 1:n_count]
    nodes_to = ["node_to_$k" for k in 1:n_count]
    nodes_from = ["node_from_$k" for k in 1:n_count]
    if add_meshed_network
        conns, conns_from, conns_to = create_meshed_network(nodes_to, n_count; max_num_connections=3)
    else
        conns = ["conn_$(k)_to_$(k + 1)" for k in 1:(n_count - 1)]
        conns_from = nodes_to[1:(end - 1)]
        conns_to = nodes_to[2:end]
    end
    objs = [
        ["model", "instance"],
        ["temporal_block", "hourly"],
        # ["temporal_block", "two_year"], # to create economic parameters
        ["stochastic_structure", "deterministic"],
        ["stochastic_scenario", "parent"],
        ["commodity", "electricity"],
        ["node", "reserve"],
        ["node", "node_group_reserve"],
    ]
    append!(objs, (["unit", u] for u in units))
    append!(objs, (["node", n] for n in nodes_to))
    append!(objs, (["node", n] for n in nodes_from))
    append!(objs, (["connection", c] for c in conns))
    rels = [
        # ["model__default_investment_temporal_block", ["instance", "two_year"]], # to create economic parameters
        ["model__default_temporal_block", ["instance", "hourly"]],
        ["model__default_stochastic_structure", ["instance", "deterministic"]],
        ["stochastic_structure__stochastic_scenario", ["deterministic", "parent"]],
    ]
    append!(rels, (["unit__to_node", (u, n)] for (u, n) in zip(units, nodes_to)))
    append!(rels, (["unit__from_node", (u, n)] for (u, n) in zip(units, nodes_from)))
    append!(rels, (["unit__node__node", (u, n1, n2)] for (u, n1, n2) in zip(units, nodes_to, nodes_from)))
    append!(rels, (["unit__from_node", (u, "reserve")] for u in units))
    append!(rels, (["node__commodity", (n, "electricity")] for n in nodes_to))
    append!(rels, (["connection__from_node", (c, n)] for (c, n) in zip(conns, conns_from)))
    append!(rels, (["connection__to_node", (c, n)] for (c, n) in zip(conns, conns_to)))
    append!(rels, (["connection__node__node", (c, n1, n2)] for (c, n1, n2) in zip(conns, conns_to, conns_from)))

    obj_pvs = [
        ["model", "instance", "model_start", unparse_db_value(DateTime(2000))],
        ["model", "instance", "model_end", unparse_db_value(DateTime(2000) + t_count * Hour(1))],
        ["model", "instance", "duration_unit", "hour"],
        ["model", "instance", "model_type", "spineopt_standard"],
        ["temporal_block", "hourly", "resolution", unparse_db_value(Hour(1))],
        ["commodity", "electricity", "commodity_physics", "commodity_physics_lodf"],
        ["node", nodes_to[1], "node_opf_type", "node_opf_type_reference"],
        ["node", "reserve", "is_reserve_node", true],
        ["node", "reserve", "upward_reserve", true],
    ]
    append!(obj_pvs, (["node", n, "demand", 1] for n in nodes_to))
    append!(obj_pvs, (["node", n, "node_state_cap", 10] for n in nodes_to))
    append!(obj_pvs, (["node", n, "has_state", true] for n in nodes_to))
    append!(obj_pvs, (["connection", c, "connection_type", "connection_type_lossless_bidirectional"] for c in conns))
    append!(obj_pvs, (["connection", c, "connection_reactance", 0.1] for c in conns))
    append!(obj_pvs, (["unit", u, "min_up_time", Dict("type" => "duration", "data" => "8h")] for u in units))
    append!(obj_pvs, (["unit", u, "min_down_time", Dict("type" => "duration", "data" => "8h")] for u in units))
    if add_investment
        # activate multi-year investments
        append!(obj_pvs, [["model", "instance", "multiyear_economic_discounting", "consecutive_years"]])
        # add investment temporal block
        append!(objs, [["temporal_block", "two_year"]])
        append!(obj_pvs, [["temporal_block", "two_year", "resolution", unparse_db_value(Year(2))]])
        append!(rels, [["model__default_investment_temporal_block", ["instance", "two_year"]]])
        # add investment candidates
        append!(obj_pvs, (["unit", u, "candidate_units", 1] for u in units))
        append!(obj_pvs, (["connection", c, "candidate_connections", 1] for c in conns))
        append!(obj_pvs, (["node", n, "candidate_storages", 1] for n in nodes_to))
        # add investment stochastic structure
        append!(rels, [["model__default_investment_stochastic_structure", ["instance", "deterministic"]]])
    end
    if add_rolling
        append!(obj_pvs, [["model", "instance", "roll_forward", unparse_db_value(Hour(168))]])
        append!(obj_pvs, [["temporal_block", "hourly", "block_start", unparse_db_value(Hour(0))]])
        append!(obj_pvs, [["temporal_block", "hourly", "block_end", unparse_db_value(Hour(168))]])
    end
    rel_pvs = []
    append!(rel_pvs, (["unit__to_node", (u, n), "unit_capacity", 1] for (u, n) in zip(units, nodes_to)))
    append!(rel_pvs, (["unit__to_node", (u, n), "ramp_up_limit", 0.9] for (u, n) in zip(units, nodes_to)))
    append!(rel_pvs, (["unit__to_node", (u, n), "ramp_down_limit", 0.9] for (u, n) in zip(units, nodes_to)))
    append!(rel_pvs, (["unit__to_node", (u, n), "minimum_operating_point", 0.2] for (u, n) in zip(units, nodes_to)))
    append!(rel_pvs, (["unit__to_node", [u, "node_group_reserve"], "unit_capacity", 0.1] for u in units))
    append!(
        rel_pvs,
        (
            ["unit__node__node", (u, n1, n2), "fix_ratio_out_in_unit_flow", 2] for
            (u, n1, n2) in zip(units, nodes_to, nodes_from)
        ),
    )
    append!(
        rel_pvs,
        (
            ["connection__node__node", (c, n1, n2), "fix_ratio_out_in_connection_flow", 2] for
            (c, n1, n2) in zip(conns, conns_to, conns_from)
        ),
    )
    append!(
        rel_pvs,
        (
            [
                "connection__node__node",
                (c, n1, n2),
                "connection_flow_delay",
                Dict("type" => "duration", "data" => "1h"),
            ] for (c, n1, n2) in zip(conns, conns_to, conns_from)
        ),
    )
    append!(rel_pvs, (["connection__from_node", (c, n), "connection_capacity", 1] for (c, n) in zip(conns, conns_from)))
    obj_grp = [["node", "node_group_reserve", "reserve"]]
    test_data = Dict(
        :objects => objs,
        :relationships => rels,
        :object_parameter_values => obj_pvs,
        :relationship_parameter_values => rel_pvs,
        :object_groups => obj_grp,
    )
    local_load_test_data(url_in, test_data)
    rm(file_path_out; force=true)

    return url_in, url_out
end

SUITE["main"] = BenchmarkGroup()

url_in_basic, url_out_basic =
    setup(number_of_weeks=1, n_count=2, add_meshed_network=true, add_investment=false, add_rolling=false)
# url_in_invest, url_out_invest = setup(number_of_weeks=1, n_count=2, add_investment=true, add_rolling=false)
# url_in_roll, url_out_roll = setup(number_of_weeks=3, n_count=50, add_investment=false, add_rolling=true)

SUITE["main", "run_spineopt", "basic"] =
    @benchmarkable run_spineopt($url_in_basic, $url_out_basic; log_level=3, optimize=false) samples = 1 evals = 1 seconds =
        Inf
# SUITE["main", "run_spineopt", "investment"] =
#     @benchmarkable run_spineopt($url_in_invest, $url_out_invest; log_level=3, optimize=false) samples = 3 evals = 1 seconds =
#         Inf
# SUITE["main", "run_spineopt", "roll"] =
#     @benchmarkable run_spineopt($url_in_roll, $url_out_roll; log_level=3, optimize=true) samples = 3 evals = 1 seconds =
#         Inf

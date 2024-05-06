using BenchmarkTools
using Dates
using SpineInterface
using SpineOpt

const SUITE = BenchmarkGroup()

#=
# To run this:
#
# - activate this env
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

function setup(; number_of_weeks=1, n_count=50, add_investment=false, add_rolling=false)
    url_in = "sqlite://"
    file_path_out = "$(@__DIR__)/test_out.sqlite"
    url_out = "sqlite:///$file_path_out"
    t_count = 24 * 7 * number_of_weeks
    units = ["unit_$k" for k in 1:n_count]
    nodes = ["node_$k" for k in 1:n_count]
    conns = ["conn_$(k)_to_$(k + 1)" for k in 1:(n_count - 1)]
    objs = [
        ["model", "instance"],
        ["temporal_block", "hourly"],
        ["stochastic_structure", "deterministic"],
        ["stochastic_scenario", "parent"],
        ["commodity", "electricity"],
    ]
    append!(objs, (["unit", u] for u in units))
    append!(objs, (["node", n] for n in nodes))
    append!(objs, (["connection", c] for c in conns))
    rels = [
        ["model__default_temporal_block", ["instance", "hourly"]],
        ["model__default_stochastic_structure", ["instance", "deterministic"]],
        ["stochastic_structure__stochastic_scenario", ["deterministic", "parent"]],
    ]
    append!(rels, (["unit__to_node", (u, n)] for (u, n) in zip(units, nodes)))
    append!(rels, (["node__commodity", (n, "electricity")] for n in nodes))
    append!(rels, (["connection__from_node", (c, n)] for (c, n) in zip(conns, nodes[1:(end - 1)])))
    append!(rels, (["connection__to_node", (c, n)] for (c, n) in zip(conns, nodes[2:end])))
    obj_pvs = [
        ["model", "instance", "model_start", unparse_db_value(DateTime(2000))],
        ["model", "instance", "model_end", unparse_db_value(DateTime(2000) + t_count * Hour(1))],
        ["model", "instance", "duration_unit", "hour"],
        ["temporal_block", "hourly", "resolution", unparse_db_value(Hour(1))],
        ["commodity", "electricity", "commodity_physics", "commodity_physics_lodf"],
        ["node", nodes[1], "node_opf_type", "node_opf_type_reference"],
    ]
    append!(obj_pvs, (["node", n, "demand", 1] for n in nodes))
    append!(obj_pvs, (["connection", c, "connection_type", "connection_type_lossless_bidirectional"] for c in conns))
    append!(obj_pvs, (["connection", c, "connection_reactance", 0.1] for c in conns))
    if add_investment
        # add investment temporal block
        append!(objs, [["temporal_block", "two_year"]])
        append!(obj_pvs, [["temporal_block", "two_year", "resolution", unparse_db_value(Year(2))]])
        append!(rels, [["model__default_investment_temporal_block", ["instance", "two_year"]]])
        # add investment candidates
        append!(obj_pvs, (["unit", u, "candidate_units", 1] for u in units))
        append!(obj_pvs, (["connection", c, "candidate_connections", 1] for c in conns))
        append!(obj_pvs, (["node", n, "candidate_storages", 1] for n in nodes))
        # add investment stochastic structure
        append!(rels, [["model__default_investment_stochastic_structure", ["instance", "deterministic"]]])
    end
    if add_rolling
        append!(obj_pvs, [["model", "instance", "roll_forward", unparse_db_value(Hour(168))]])
        append!(obj_pvs, [["temporal_block", "hourly", "block_start", unparse_db_value(Hour(0))]])
        append!(obj_pvs, [["temporal_block", "hourly", "block_end", unparse_db_value(Hour(168))]])
    end
    rel_pvs = []
    append!(rel_pvs, (["unit__to_node", (u, n), "unit_capacity", 1] for (u, n) in zip(units, nodes)))
    append!(
        rel_pvs,
        (["connection__from_node", (c, n), "connection_capacity", 1] for (c, n) in zip(conns, nodes[1:(end - 1)])),
    )
    test_data = Dict(
        :objects => objs,
        :relationships => rels,
        :object_parameter_values => obj_pvs,
        :relationship_parameter_values => rel_pvs,
    )
    local_load_test_data(url_in, test_data)
    rm(file_path_out; force=true)

    return url_in, url_out
end

SUITE["main"] = BenchmarkGroup()

url_in_basic, url_out_basic = setup(number_of_weeks=3, n_count=50, add_investment=false, add_rolling=false)
url_in_invest, url_out_invest = setup(number_of_weeks=3, n_count=10, add_investment=true, add_rolling=false)
url_in_roll, url_out_roll = setup(number_of_weeks=3, n_count=50, add_investment=false, add_rolling=true)

SUITE["main", "run_spineopt", "basic"] =
    @benchmarkable run_spineopt($url_in_basic, $url_out_basic; log_level=3, optimize=false) samples = 3 evals = 1 seconds =
        Inf
SUITE["main", "run_spineopt", "investment"] =
    @benchmarkable run_spineopt($url_in_invest, $url_out_invest; log_level=3, optimize=false) samples = 3 evals = 1 seconds =
        Inf
SUITE["main", "run_spineopt", "roll"] =
    @benchmarkable run_spineopt($url_in_roll, $url_out_roll; log_level=3, optimize=true) samples = 3 evals = 1 seconds =
        Inf

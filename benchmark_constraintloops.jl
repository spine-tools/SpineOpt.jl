#### How to use:
# run test_system3.jl to get database and flow Dict
# then run this script

using BenchmarkTools
using Statistics

benchmark_over_relationships() = [(c,n,u,d,t) for (c,n,u,d,tblock) in commodity__node__unit__direction__temporal_block() for t in time_slice(temporal_block = tblock)]
benchmark_over_flowkeys() = [test for test in keys(flow)]

benchmark_over_relationships_withcondition() = [(c,n,u,d,t) for u in unit__out_commodity_group__in_commodity_group(commodity_group1 = :cg2,commodity_group2 = :cg1) for (c,n,d,tblock) in commodity__node__unit__direction__temporal_block(unit = u) for t in time_slice(temporal_block = tblock)]
benchmark_over_flowkeys_withcondition() = [test for test in keys(flow) if test[3] in unit__out_commodity_group__in_commodity_group(commodity_group1 = :cg2,commodity_group2 = :cg1)]

println("Runtime for creating all sets of (c,n,u,d,t) using relationships")
over_relationships = @benchmark benchmark_over_relationships()
@show median(over_relationships)
println("Runtime for creating all sets of (c,n,u,d,t) using flow keys")
over_flowkeys = @benchmark benchmark_over_flowkeys()
@show median(over_flowkeys)

println("Runtime for creating all sets of (c,n,u,d,t) using relationships with constrained units")
over_relationships_withcondition = @benchmark benchmark_over_relationships_withcondition()
@show median(over_relationships_withcondition)
println("Runtime for creating all sets of (c,n,u,d,t) using flow keys with constrained units")
over_flowkeys_withcondition = @benchmark benchmark_over_flowkeys_withcondition()
@show median(over_flowkeys_withcondition)

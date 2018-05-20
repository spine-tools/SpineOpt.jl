"""
Aggregates the values of `parameter` into one single value for each `object`.
Child objects are determined via `relationship`, and `func` is applied to compute
the value for the parent.
"""
function aggregate_parameter(parameter::Dict;
        object=Array(),
        relationship=Dict(),
        func=x->nothing
    )
    Dict(
        parent => func([parameter[child] for child in relationship[parent]])
        for parent in object
    )
end

"""
adds equivalent buses to `system` according to `assignments`
and creates relationships between these equivalent and the original buses
"""
function aggregate_buses!(dst::Dict, src::Dict, assignments::Vector{Int}, costs::Vector{Float64})
    @JuMPout_suffix(src, 0, bus)
    bus = [string("eqbus", z) for z in unique(assignments)]
    bus_bus0 = Dict(string("eqbus", z) => [bus0[n] for n in findin(assignments, z)] for z in unique(assignments))
    bus0_bus = Dict(bus0[n] => string("eqbus", z) for (n, z) in enumerate(assignments))
    bus0_bus = merge(bus0_bus, bus_bus0)
    counts = Dict(z => count(assignments .== z) for z in unique(assignments))
    totalcosts = Dict(z => sum(costs[assignments .== z]) for z in unique(assignments))
    bus0_weight = Dict(
        bus0[n] => (counts[z] > 1)?(1 - costs[n] / totalcosts[z]) / (counts[z] - 1):1
        for (n,z) in enumerate(assignments)
    )
    bus_internalbus0 = Dict(
        string("eqbus", z) => bus0[indmin(costs + (assignments .!= z) * Inf)]    #the internal bus is the one with the minimum cost among the ones in the zone
        for z in unique(assignments)
    )
    #bus_internalbus0 = Dict(
    #    string(z) => bus0[findfirst(assignments .== z)]    #the internal bus is the first one for that zone in the vector
    #    for z in unique(assignments)
    #)
    @JuMPin(dst, bus, bus0_bus, bus0_weight, bus_internalbus0)
    add_object_class_metadata!(dst, "bus")
end

function aggregate_basic_bus_params!(dst::Dict, src::Dict)
    @JuMPout_suffix(src, 0, bus_type, vm, va, vmax, vmin)
    @JuMPout(dst, bus, bus0_bus, bus0_weight)
    bus_type = aggregate_parameter(bus_type0, object=bus, relationship=bus0_bus, func=maximum)
    vm = aggregate_parameter(prod(vm0, bus0_weight), object=bus, relationship=bus0_bus, func=sum)
    va = aggregate_parameter(prod(va0, bus0_weight), object=bus, relationship=bus0_bus, func=sum)
    vmax = aggregate_parameter(vmax0, object=bus, relationship=bus0_bus, func=minimum)
    vmin = aggregate_parameter(vmin0, object=bus, relationship=bus0_bus, func=maximum)
    @JuMPin(dst, bus_type, vm, va, vmax, vmin)
    add_parameter_metadata!(dst, "bus_type", "vm", "va", "vmax", "vmin")
end

#function aggregate_basic_bus_params!(dst::Dict, src::Dict)
#    @JuMPout_suffix(src, 0, bus_type, vm, va, vmax, vmin)
#    @JuMPout(dst, bus0_bus, bus_internalbus0)
#    bus_type = aggregate_parameter(bus_type0, bus0_bus, maximum)
#    vm = extend_parameter(vm0, bus_internalbus0)
#    va = extend_parameter(va0, bus_internalbus0)
#    vmax = extend_parameter(vmax0, bus_internalbus0)
#    vmin = extend_parameter(vmin0, bus_internalbus0)
#    @JuMPin(dst, bus_type, vm, va, vmax, vmin)
#end

function aggregate_basic_dc_branch_params!(dst::Dict, src::Dict)
    @JuMPout_suffix(src, 0, rate_a, pf)
    @JuMPout(dst, flowdir0, branch0_branch, branch)
    rate_a = aggregate_parameter(rate_a0, object=branch, relationship=branch0_branch, func=sum)
    pf_sp = aggregate_parameter(prod(pf0, flowdir0), object=branch, relationship=branch0_branch, func=sum)
    for l in branch
        if !in(l, values(branch0_branch))
            rate_a[l] =  Inf
            pf_sp[l] = 0
        end
    end
    @JuMPin(dst, rate_a, pf_sp)
    add_parameter_metadata!(dst, "rate_a")
end

function aggregate_basic_ac_branch_params!(dst::Dict, src::Dict)
    @JuMPout_suffix(src, 0, rate_a, pf_fr, qf_fr, pf_to, qf_to)
    @JuMPout(dst, flowdir0, branch0_branch, branch)
    rate_a = aggregate_parameter(rate_a0, object=branch, relationship=branch0_branch, func=sum)
    pf_fr_sp = aggregate_parameter(prod(pf_fr0, flowdir0), object=branch, relationship=branch0_branch, func=sum)
    qf_fr_sp = aggregate_parameter(prod(qf_fr0, flowdir0), object=branch, relationship=branch0_branch, func=sum)
    pf_to_sp = aggregate_parameter(prod(pf_to0, flowdir0), object=branch, relationship=branch0_branch, func=sum)
    qf_to_sp = aggregate_parameter(prod(qf_to0, flowdir0), object=branch, relationship=branch0_branch, func=sum)
    for l in branch
        if !in(l, values(branch0_branch))
            rate_a[l] =  Inf
            pf_fr_sp[l] = 0
            qf_fr_sp[l] = 0
            pf_to_sp[l] = 0
            qf_to_sp[l] = 0
        end
    end
    @JuMPin(dst, rate_a, pf_fr_sp, qf_fr_sp, pf_to_sp, qf_to_sp)
    add_parameter_metadata!(dst, "rate_a")
end

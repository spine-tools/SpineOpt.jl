#This is previous to split equivalent and original system into two different dictionaries

using StatsBase
using Distances
import StatsBase: IntegerVector, RealMatrix, counts

function initseeds(k::Int, X::RealMatrix, metric::PreMetric = SqEuclidean(); first_seed = x -> rand(1:x))
    n = size(X, 2)
    iseeds = Vector{Int}(k)
    Clustering.check_seeding_args(n, k)

    # randomly pick the first center
    p = first_seed(n)
    iseeds[1] = p

    if k > 1
        mincosts = Distances.colwise(metric, X, view(X,:,p))
        mincosts[p] = 0

        # pick remaining (with a chance proportional to mincosts)
        tmpcosts = zeros(n)
        for j = 2:k
            p = wsample(1:n, mincosts)
            iseeds[j] = p

            # update mincosts
            c = view(X,:,p)
            colwise!(tmpcosts, metric, X, view(X,:,p))
            Clustering.updatemin!(mincosts, tmpcosts)
            mincosts[p] = 0
        end
    end

    return iseeds
end




"""
Computes an array of bus to zone assignments based on PTDF matrix
"""
function PTDF_bus_clustering(ref::Dict, m::Int = 4; first_seed = x -> rand(1:x))
    phi = compute_PTDF_matrix(ref)
    int_br_id = find(l -> ref["internal"][l] == 1, ref["branch"])
    phi_prime = phi[int_br_id, :]
    iseeds = initseeds(m, phi_prime; first_seed = first_seed)
    kmres = kmeans(phi_prime, m; init = iseeds)
    kmres.assignments, kmres.costs
    #collect(1:24), zeros(24)
end

"""
adds equivalent branches and corresponding relationships to a `system`
that already has equivalent buses defined
"""
function PTDF_aggregate_branches!(dst::Dict, src::Dict)
    branch = Array{String,1}()
    branch0_branch = Dict{String,String}()
    f_bus = Dict{String,String}()
    t_bus = Dict{String,String}()
    flowdir0 = Dict{String,Any}()
    k = 1
    @JuMPout(dst, bus, bus0_bus)
    @JuMPout_suffix(src, 0, branch, f_bus, t_bus)
    for a in eachindex(bus), b in eachindex(bus)
        if b > a
            bus_a = bus[a]
            bus_b = bus[b]
            branch0_ab = filter(
                l -> bus0_bus[f_bus0[l]] == bus_a
                    && bus0_bus[t_bus0[l]] == bus_b,
                branch0
            )
            branch0_ba = filter(
                l -> bus0_bus[f_bus0[l]] == bus_b
                    && bus0_bus[t_bus0[l]] == bus_a,
                branch0
            )
            if !isempty(union(branch0_ab, branch0_ba))
                push!(branch, string(k))
                push!(f_bus, string(k) => bus_a)
                push!(t_bus, string(k) => bus_b)
                for l in branch0_ab
                    push!(branch0_branch, l => string(k))
                    push!(flowdir0, l => 1)
                end
                for l in branch0_ba
                    push!(branch0_branch, l => string(k))
                    push!(flowdir0, l => -1)
                end
                k += 1
            end
        end
    end
    @JuMPin(dst, branch, branch0_branch, f_bus, t_bus, flowdir0)
end

function PTDF_aggregate_basic_bus_params!(dst::Dict, src::Dict)
    @JuMPout_suffix(src, 0, bus_type, pd, qd, vm, vmax, vmin, gen_bus)
    @JuMPout(dst, bus0_bus, bus0_weight)
    pd = aggregate_parameter(pd0, bus0_bus, sum)
    qd = aggregate_parameter(qd0, bus0_bus, sum)
    gen_bus = extend_relationship(gen_bus0, bus0_bus)
    @JuMPin(dst, pd, qd, gen_bus)
end

function PTDF_compute_dc_aggregated_branch_params!(dst::Dict; solver = SCIPSolver())
    @JuMPout(dst, bus, bus_type, branch, f_bus, t_bus, pf_sp)
    m = Model(solver = solver)
    @variable(m, x[branch])
    @variable(m, va[bus])
    @constraint(m, [n in bus; bus_type[n] == 3], va[n] == 0)
    @constraint(m, ohms[l in branch],
        pf_sp[l] * x[l] == va[f_bus[l]] - va[t_bus[l]]
    )
    @constraint(m, [l in branch], x[l]^2 >= 1e-3)
    #println(m)
    status = solve(m)
    br_x = Dict(l => getvalue(x[l]) for l in branch)
    @JuMPin(dst, br_x)
end


"""
Aggregate a `system` into `m` zones while preserving inter-zonal flows
internal branches in the system are preserved in the aggregate
"""
function PTDF_dc_aggregate!(dst::Dict, src::Dict, m::Int = 4)
    run_dc_pf!(src)
    assignments, costs = PTDF_bus_clustering(src, m)
    aggregate_buses!(dst, src, assignments, costs)
    PTDF_aggregate_branches!(dst, src)
    aggregate_basic_bus_params!(dst, src)
    PTDF_aggregate_basic_bus_params!(dst, src)
    aggregate_basic_dc_branch_params!(dst, src)
    PTDF_compute_dc_aggregated_branch_params!(dst)
end

function PTDF_compute_ac_aggregated_bus_branch_params!(dst::Dict, src::Dict; solver = IpoptSolver(print_level = 0, linear_solver = "ma97"))
    @JuMPout_with_backup(dst, src,
        bus, branch, gen, f_bus, t_bus, gen_bus, pf_fr_sp, qf_fr_sp, pf_to_sp, qf_to_sp,
        vm, vmax, vmin, bus_type, pd, qd, pg, qg, qmax, qmin)
    m = Model(solver = solver)
    @variable(m, g[branch], lowerbound = 0)
    @variable(m, b[branch])
    @variable(m, c[branch])
    @variable(m, t[branch], lowerbound = 0, upperbound = 1)
    @variable(m, s[branch], lowerbound = -pi, upperbound = pi)
    @variable(m, gs[bus] >= 0, start = 1.0)
    @variable(m, bs[bus], start = 1.0)
    @variable(m, vmag[n in bus], upperbound = vmax[n], lowerbound = vmin[n], start = 1.0)
    @variable(m, va[bus], start = 0.0)
    @variable(m, pgen[g in gen], start = pg[g])
    @variable(m, qgen[g in gen], start = qg[g])

    @constraint(m, [n in bus; bus_type[n] == 3], va[n] == 0)
    @constraint(m, [n in bus; bus_type[n] in (2,3)], vmag[n] == vm[n])
    @constraint(m, [g in gen; bus_type[gen_bus[g]] == 2], pgen[g] == pg[g])
    @constraint(m, [g in gen; bus_type[gen_bus[g]] == 2], qgen[g] <= qmax[g])
    @constraint(m, [g in gen; bus_type[gen_bus[g]] == 2], qgen[g] >= qmin[g])

    constraint_ac_kcl_p(m, bus, branch, gen, f_bus, t_bus, gen_bus, vmag, gs, pd, pf_fr_sp, pf_to_sp, pgen)
    constraint_ac_kcl_q(m, bus, branch, gen, f_bus, t_bus, gen_bus, vmag, bs, qd, qf_fr_sp, qf_to_sp, qgen)

    constraint_ac_ohms_p_fr(m, branch, f_bus, t_bus, pf_fr_sp, g, b, t, s, vmag, va)
    constraint_ac_ohms_q_fr(m, branch, f_bus, t_bus, qf_fr_sp, g, b, c, t, s, vmag, va)
    constraint_ac_ohms_p_to(m, branch, f_bus, t_bus, pf_to_sp, g, b, t, s, vmag, va)
    constraint_ac_ohms_q_to(m, branch, f_bus, t_bus, qf_to_sp, g, b, c, t, s, vmag, va)

    #println(m)
    status = solve(m)
    status != :Optimal && (print_with_color(:red, "Failed to determine equivalent ac bus and branch parameters\n"); return false)
    g = Dict(l => getvalue(g[l]) for l in branch)
    b = Dict(l => getvalue(b[l]) for l in branch)
    br_r = Dict(l => g[l] / (g[l]^2 + b[l]^2) for l in branch)
    br_x = Dict(l => -b[l] / (g[l]^2 + b[l]^2) for l in branch)
    br_b = Dict(l => getvalue(c[l]) for l in branch)
    tap = Dict(l => getvalue(t[l]) for l in branch)
    shift = Dict(l => getvalue(s[l]) for l in branch)
    gs = Dict(n => getvalue(gs[n]) for n in bus)
    bs = Dict(n => getvalue(bs[n]) for n in bus)
    vmag_start = Dict(n => getvalue(vmag[n]) for n in bus)
    va_start = Dict(n => getvalue(va[n]) for n in bus)
    @JuMPin(dst, br_r, br_x, br_b, tap, shift, gs, bs)
    print_with_color(:green, "Equivalent ac bus and branch parameters determined successfully\n")
    true
end

"""
Aggregate a `system` into `m` zones while preserving inter-zonal flows
internal branches in the system are preserved in the aggregate
"""
function PTDF_ac_aggregate!(dst::Dict, src::Dict, m::Int = 4; max_iters::Int = 20 )
    run_ac_pf!(src)
    for iter = 1:max_iters
        assignments, costs = PTDF_bus_clustering(src, m; first_seed = x -> iter)
        aggregate_buses!(dst, src, assignments, costs)
        PTDF_aggregate_branches!(dst, src)
        aggregate_basic_bus_params!(dst, src)
        PTDF_aggregate_basic_bus_params!(dst, src)
        aggregate_basic_ac_branch_params!(dst, src)
        !PTDF_compute_ac_aggregated_bus_branch_params!(dst, src) && continue
        return true
    end
    print_with_color(:red, "PTDF_ac_aggregate: Maximum number of iterations reached")
    false
end

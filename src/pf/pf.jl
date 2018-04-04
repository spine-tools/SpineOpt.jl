function run_dc_pf!(
        ref::Dict;
        solver = CplexSolver(),
        bck = Dict()
        )

    @unpack_with_backup(ref, bck, bus, branch, gen, rate_a, bus_type, gen_bus, f_bus, t_bus, br_x, pd, pg)

    m = Model(solver = solver)

    @variable(m, va[bus])
    @variable(m, pf[l in branch],
        upperbound = rate_a[l],
        lowerbound = -rate_a[l])
    @variable(m, pgen[gen])

    @constraint(m, [n in bus; bus_type[n] == 3], va[n] == 0)
    @constraint(m, kcl[n in bus],
        sum(pgen[g] for g in gen if gen_bus[g] == n)
        - pd[n]
        == sum(pf[l] for l in branch if t_bus[l] == n)
        - sum(pf[l] for l in branch if f_bus[l] == n)
    )
    @constraint(m, ohms[l in branch],
        pf[l] == (1 / br_x[l]) * (va[f_bus[l]] - va[t_bus[l]])
    )
    @constraint(m, [g in gen; bus_type[gen_bus[g]] == 2],
        pgen[g] == pg[g]
    )
    #println(m)
    status = solve(m)
    va = Dict(n => getvalue(va[n]) for n in bus)
    pg = Dict(g => getvalue(pgen[g]) for g in gen)
    pf = Dict(l => getvalue(pf[l]) for l in branch)
    @pack(ref, va, pg, pf)
end

function constraint_ac_kcl_p(m, bus, branch, gen, f_bus, t_bus, gen_bus, vmag, gs, pd, pf_fr, pf_to, pgen)
    @NLconstraint(m, kcl_p[n in bus],
        sum(pgen[g] for g in gen if gen_bus[g] == n)
        - pd[n] - gs[n] * vmag[n]^2
        == - sum(pf_fr[l] for l in branch if f_bus[l] == n)
        + sum(pf_to[l] for l in branch if t_bus[l] == n)
    )
end


function constraint_ac_kcl_q(m, bus, branch, gen, f_bus, t_bus, gen_bus, vmag, bs, qd, qf_fr, qf_to, qgen)
    @NLconstraint(m, kcl_q[n in bus],
        sum(qgen[g] for g in gen if gen_bus[g] == n)
        - qd[n] + bs[n] * vmag[n]^2
        == - sum(qf_fr[l] for l in branch if f_bus[l] == n)
        + sum(qf_to[l] for l in branch if t_bus[l] == n)
    )
end

function constraint_ac_ohms_p_fr(m, branch, f_bus, t_bus, pf_fr, g, b, t, s, vmag, va)
    @NLexpression(m, ang[l in branch], va[f_bus[l]] - va[t_bus[l]] - s[l])
    @NLconstraint(m, ohms_p_fr[l in branch],
        - pf_fr[l] == g[l] * (vmag[f_bus[l]] / t[l])^2
        - (g[l] * cos(ang[l]) + b[l] * sin(ang[l])) * vmag[f_bus[l]] * vmag[t_bus[l]] / t[l]
    )
end

function constraint_ac_ohms_q_fr(m, branch, f_bus, t_bus, qf_fr, g, b, c, t, s, vmag, va)
    @NLexpression(m, ang[l in branch], va[f_bus[l]] - va[t_bus[l]] - s[l])
    @NLconstraint(m, ohms_q_fr[l in branch],
        -qf_fr[l] == -(b[l] + c[l] / 2) * (vmag[f_bus[l]] / t[l])^2
        + (b[l] * cos(ang[l]) - g[l] * sin(ang[l])) * vmag[f_bus[l]] * vmag[t_bus[l]] / t[l]
    )
end

function constraint_ac_ohms_p_to(m, branch, f_bus, t_bus, pf_to, g, b, t, s, vmag, va)
    @NLexpression(m, ang[l in branch], va[t_bus[l]] - va[f_bus[l]] - s[l])
    @NLconstraint(m, ohms_p_to[l in branch],
        pf_to[l] == g[l] * vmag[t_bus[l]]^2
        - (g[l] * cos(ang[l]) + b[l] * sin(ang[l])) * vmag[t_bus[l]] * vmag[f_bus[l]] / t[l]
    )
end

function constraint_ac_ohms_q_to(m, branch, f_bus, t_bus, qf_to, g, b, c, t, s, vmag, va)
    @NLexpression(m, ang[l in branch], va[t_bus[l]] - va[f_bus[l]] - s[l])
    @NLconstraint(m, ohms_q_to[l in branch],
        qf_to[l] == -(b[l] + c[l] / 2) * vmag[t_bus[l]]^2
        + (b[l] * cos(ang[l]) - g[l] * sin(ang[l])) * vmag[t_bus[l]] * vmag[f_bus[l]] / t[l]
    )
end

##RECT COORDS
function constraint_ac_rect_kcl_p(m, bus, branch, gen, f_bus, t_bus, gen_bus, vr, vi, gs, pd, pf_fr, pf_to, pgen)
    @NLconstraint(m, kcl_p[n in bus],
        sum(pgen[g] for g in gen if gen_bus[g] == n)
        - pd[n] - gs[n] * (vr[n]^2 + vi[n]^2)
        == - sum(pf_fr[l] for l in branch if f_bus[l] == n)
        + sum(pf_to[l] for l in branch if t_bus[l] == n)
    )
end

function constraint_ac_rect_kcl_q(m, bus, branch, gen, f_bus, t_bus, gen_bus, vr, vi, bs, qd, qf_fr, qf_to, qgen)
    @NLconstraint(m, kcl_q[n in bus],
        sum(qgen[g] for g in gen if gen_bus[g] == n)
        - qd[n] + bs[n] * (vr[n]^2 + vi[n]^2)
        == - sum(qf_fr[l] for l in branch if f_bus[l] == n)
        + sum(qf_to[l] for l in branch if t_bus[l] == n)
    )
end

function constraint_ac_rect_ohms_p_fr(m, branch, f_bus, t_bus, pf_fr, g, b, tr, ti, vr, vi)
    @NLconstraint(m, ohms_p_fr[l in branch],
        -pf_fr[l] == g[l] * (vr[f_bus[l]]^2 + vi[f_bus[l]]^2) / (tr[l]^2 + ti[l]^2)
        + (-g[l] * tr[l] + b[l] * ti[l]) * (vr[f_bus[l]] * vr[t_bus[l]] + vi[f_bus[l]] * vi[t_bus[l]]) / (tr[l]^2 + ti[l]^2)
        + (-b[l] * tr[l] - g[l] * ti[l]) * (vi[f_bus[l]] * vr[t_bus[l]] - vr[f_bus[l]] * vi[t_bus[l]]) / (tr[l]^2 + ti[l]^2)
    )
end

function constraint_ac_rect_ohms_q_fr(m, branch, f_bus, t_bus, qf_fr, g, b, c, tr, ti, vr, vi)
    @NLconstraint(m, ohms_q_fr[l in branch],
        -qf_fr[l] == -(b[l] + c[l] / 2) * (vr[f_bus[l]]^2 + vi[f_bus[l]]^2) / (tr[l]^2 + ti[l]^2)
        + (b[l] * tr[l] + g[l] * ti[l]) * (vr[f_bus[l]] * vr[t_bus[l]] + vi[f_bus[l]] * vi[t_bus[l]]) / (tr[l]^2 + ti[l]^2)
        + (-g[l] * tr[l] + b[l] * ti[l]) * (vi[f_bus[l]] * vr[t_bus[l]] - vr[f_bus[l]] * vi[t_bus[l]]) / (tr[l]^2 + ti[l]^2)
    )
end

function constraint_ac_rect_ohms_p_to(m, branch, f_bus, t_bus, pf_to, g, b, tr, ti, vr, vi)
    @NLconstraint(m, ohms_p_to[l in branch],
        pf_to[l] == g[l] * (vr[t_bus[l]]^2 + vi[t_bus[l]]^2)
        - (g[l] * tr[l] + b[l] * ti[l]) * (vr[f_bus[l]] * vr[t_bus[l]] + vi[f_bus[l]] * vi[t_bus[l]]) / (tr[l]^2 + ti[l]^2)
        + (b[l] * tr[l] - g[l] * ti[l]) * (vi[f_bus[l]] * vr[t_bus[l]] - vr[f_bus[l]] * vi[t_bus[l]]) / (tr[l]^2 + ti[l]^2)
    )
end

function constraint_ac_rect_ohms_q_to(m, branch, f_bus, t_bus, qf_to, g, b, c, tr, ti, vr, vi)
    @NLconstraint(m, ohms_q_to[l in branch],
        qf_to[l] == -(b[l] + c[l] / 2) * (vr[t_bus[l]]^2 + vi[t_bus[l]]^2)
        + (b[l] * tr[l] - g[l] * ti[l]) * (vr[f_bus[l]] * vr[t_bus[l]] + vi[f_bus[l]] * vi[t_bus[l]]) / (tr[l]^2 + ti[l]^2)
        + (g[l] * tr[l] + b[l] * ti[l]) * (vi[f_bus[l]] * vr[t_bus[l]] - vr[f_bus[l]] * vi[t_bus[l]]) / (tr[l]^2 + ti[l]^2)
    )
end

function run_ac_pf!(ref::Dict;
        solver = IpoptSolver(print_level = 0, linear_solver = "ma97"),
        bck = Dict()
        )
    print_with_color(:yellow, "\nRunning ac powerflow...\n")

    @unpack_with_backup(ref, bck, bus, branch, gen, bus_type, vm, vmax, vmin, gs, bs, rate_a,
        qmax, qmin, gen_bus, f_bus, t_bus, br_r, br_x, br_b, tap, shift, pd, qd, pg)

    g = Dict(l => br_r[l] / (br_r[l]^2 + br_x[l]^2) for l in branch)
    b = Dict(l => -br_x[l] / (br_r[l]^2 + br_x[l]^2) for l in branch)
    c = Dict(l => br_b[l] for l in branch)
    t = Dict(l => (tap[l] == 0)?1:tap[l] for l in branch)
    s = Dict(l => shift[l] for l in branch)

    m = Model(solver = solver)

    @variable(m, va[n in bus])
    @variable(m, vmag[n in bus], upperbound = vmax[n], lowerbound = vmin[n])
    @variable(m, pf_fr[l in branch], upperbound = rate_a[l], lowerbound = -rate_a[l])
    @variable(m, qf_fr[l in branch], upperbound = rate_a[l], lowerbound = -rate_a[l])
    @variable(m, pf_to[l in branch], upperbound = rate_a[l], lowerbound = -rate_a[l])
    @variable(m, qf_to[l in branch], upperbound = rate_a[l], lowerbound = -rate_a[l])
    @variable(m, pgen[g in gen])
    @variable(m, qgen[g in gen])

    @constraint(m, [n in bus; bus_type[n] == 3], va[n] == 0)
    @constraint(m, [n in bus; bus_type[n] in (2,3)], vmag[n] == vm[n])
    @constraint(m, [g in gen; bus_type[gen_bus[g]] == 2], pgen[g] == pg[g])
    @constraint(m, [g in gen; bus_type[gen_bus[g]] == 2], qgen[g] <= qmax[g])
    @constraint(m, [g in gen; bus_type[gen_bus[g]] == 2], qgen[g] >= qmin[g])

    constraint_ac_kcl_p(m, bus, branch, gen, f_bus, t_bus, gen_bus, vmag, gs, pd, pf_fr, pf_to, pgen)
    constraint_ac_kcl_q(m, bus, branch, gen, f_bus, t_bus, gen_bus, vmag, bs, qd, qf_fr, qf_to, qgen)

    constraint_ac_ohms_p_fr(m, branch, f_bus, t_bus, pf_fr, g, b, t, s, vmag, va)
    constraint_ac_ohms_q_fr(m, branch, f_bus, t_bus, qf_fr, g, b, c, t, s, vmag, va)
    constraint_ac_ohms_p_to(m, branch, f_bus, t_bus, pf_to, g, b, t, s, vmag, va)
    constraint_ac_ohms_q_to(m, branch, f_bus, t_bus, qf_to, g, b, c, t, s, vmag, va)

    #println(m)
    status = solve(m)
    status != :Optimal && (print_with_color(:red, "Failed to solve ac power flow\n"); return false)
    vm = Dict(n => getvalue(vmag[n]) for n in bus)
    va = Dict(n => getvalue(va[n]) for n in bus)
    pg = Dict(g => getvalue(pgen[g]) for g in gen)
    qg = Dict(g => getvalue(qgen[g]) for g in gen)
    pf_fr = Dict(l => getvalue(pf_fr[l]) for l in branch)
    qf_fr = Dict(l => getvalue(qf_fr[l]) for l in branch)
    pf_to = Dict(l => getvalue(pf_to[l]) for l in branch)
    qf_to = Dict(l => getvalue(qf_to[l]) for l in branch)

    @pack(ref, va, vm, pg, qg, pf_fr, qf_fr, pf_to, qf_to)
    print_with_color(:green, "ac power flow solved successfully\n")
    true
end


function test_ac_rect_pf!(ref::Dict;
        solver = IpoptSolver(),
        rin = Dict{String,String}(),
        rout = Dict{String,String}()
        )

    @unpack(ref, rin, bus, branch, gen, bus_type, vm, va_start, vmax, vmin, gs, bs, rate_a,
        qmax, qmin, gen_bus, f_bus, t_bus, br_r, br_x, br_b, tap, shift, pd, qd, pg)

    g = Dict(l => br_r[l] / (br_r[l]^2 + br_x[l]^2) for l in branch)
    b = Dict(l => -br_x[l] / (br_r[l]^2 + br_x[l]^2) for l in branch)
    c = Dict(l => br_b[l] for l in branch)
    t = Dict(l => (tap[l] == 0)?1:tap[l] for l in branch)
    tr = Dict(l => t[l] * cos(shift[l]) for l in branch)
    ti = Dict(l => t[l] * sin(shift[l]) for l in branch)

    m = Model(solver = solver)

    @variable(m, vr[n in bus], start = 1.0)
    @variable(m, vi[n in bus], start = 1.0)
    @variable(m, pf_fr[l in branch], upperbound = rate_a[l], lowerbound = -rate_a[l])
    @variable(m, pf_to[l in branch], upperbound = rate_a[l], lowerbound = -rate_a[l])
    @variable(m, qf_fr[l in branch], upperbound = rate_a[l], lowerbound = -rate_a[l])
    @variable(m, qf_to[l in branch], upperbound = rate_a[l], lowerbound = -rate_a[l])
    @variable(m, pgen[gen])
    @variable(m, qgen[gen])

#TODO: add vmax vmin constraints
    @constraint(m, [n in bus; bus_type[n] == 3], vi[n] == 0)
    @NLconstraint(m, [n in bus; bus_type[n] in (2,3)], vr[n]^2 + vi[n]^2 == vm[n]^2)
    @constraint(m, [g in gen; bus_type[gen_bus[g]] == 2], pgen[g] == pg[g])
    @constraint(m, [g in gen; bus_type[gen_bus[g]] == 2], qgen[g] <= qmax[g])
    @constraint(m, [g in gen; bus_type[gen_bus[g]] == 2], qgen[g] >= qmin[g])

    constraint_ac_rect_kcl_p(m, bus, branch, gen, f_bus, t_bus, gen_bus, vr, vi, gs, pd, pf_fr, pf_to, pgen)
    constraint_ac_rect_kcl_q(m, bus, branch, gen, f_bus, t_bus, gen_bus, vr, vi, bs, qd, qf_fr, qf_to, qgen)

    constraint_ac_rect_ohms_p_fr(m, branch, f_bus, t_bus, pf_fr, g, b, tr, ti, vr, vi)
    constraint_ac_rect_ohms_q_fr(m, branch, f_bus, t_bus, qf_fr, g, b, c, tr, ti, vr, vi)
    constraint_ac_rect_ohms_p_to(m, branch, f_bus, t_bus, pf_to, g, b, tr, ti, vr, vi)
    constraint_ac_rect_ohms_q_to(m, branch, f_bus, t_bus, qf_to, g, b, c, tr, ti, vr, vi)

    #println(m)
    status = solve(m)
    vm = Dict(n => sqrt(getvalue(vr[n])^2 + getvalue(vi[n])^2) for n in bus)
    va = Dict(n => atan(getvalue(vi[n]) / getvalue(vr[n])) for n in bus)
    pg = Dict(g => getvalue(pgen[g]) for g in gen)
    qg = Dict(g => getvalue(qgen[g]) for g in gen)
    pf_fr = Dict(l => getvalue(pf_fr[l]) for l in branch)
    qf_fr = Dict(l => getvalue(qf_fr[l]) for l in branch)
    pf_to = Dict(l => getvalue(pf_to[l]) for l in branch)
    qf_to = Dict(l => getvalue(qf_to[l]) for l in branch)

    @pack(ref, rout, va, vm, pg, qg, pf_fr, qf_fr, pf_to, qf_to)
end

#TODO: check if correct with small system
function compute_admittance_matrix(ref::Dict)
    @unpack(ref, bus, gs, bs, branch, f_bus, t_bus, br_r, br_x, br_b, tap, shift)
    n = length(bus)
    Y = spzeros(Complex{Float64}, n, n)
    for l in branch
        fr = findfirst(bus .== f_bus[l])
        to = findfirst(bus .== t_bus[l])
        r = br_r[l]
        x = br_x[l]
        c = br_b[l]
        t = tap[l] == 0?1:tap[l]
        s = shift[l]
        y = 1 / (r + im * x)
        a = t * (cos(s) + im * sin(s))
        Y[fr,to] -= y / conj(a)
        Y[to,fr] -= y / a
        Y[fr,fr] += (y + im * 0.5 * c) / a^2
        Y[to,to] += y + im * 0.5 * c
    end
    for (i, n) in enumerate(bus)
        y = gs[n] + im * bs[n]
        Y[i,i] += y
    end
    Y
end

function compute_current_vectors(ref::Dict)
    @unpack(ref, bus, gen, gen_bus, pg, qg, pmax, qmax, pmin, qmin, pd, qd, vm, va)
    pg_vec = [reduce(+, 0, [pg[g] for g in gen if gen_bus[g] == n]) for n in bus]
    qg_vec = [reduce(+, 0, [qg[g] for g in gen if gen_bus[g] == n]) for n in bus]
    pmin_vec = [reduce(+, 0, [pmin[g] for g in gen if gen_bus[g] == n]) for n in bus]
    qmin_vec = [reduce(+, 0, [qmin[g] for g in gen if gen_bus[g] == n]) for n in bus]
    pmax_vec = [reduce(+, 0, [pmax[g] for g in gen if gen_bus[g] == n]) for n in bus]
    qmax_vec = [reduce(+, 0, [qmax[g] for g in gen if gen_bus[g] == n]) for n in bus]
    pd_vec = [pd[n] for n in bus]
    qd_vec = [qd[n] for n in bus]
    vm_vec = [vm[n] for n in bus]
    va_vec = [va[n] for n in bus]
    v_vec = vm_vec .* (cos.(va_vec) + im * sin.(va_vec))
    ig_vec = conj((pg_vec + im * qg_vec) ./ v_vec)
    imin_vec = conj((pmin_vec + im * qmin_vec) ./ v_vec)
    imax_vec = conj((pmax_vec + im * qmax_vec) ./ v_vec)
    ig_ext_vec = [[ig_vec[i], imin_vec[i], imax_vec[i]] for i in eachindex(ig_vec)]
    id_vec = conj((pd_vec + im * qd_vec) ./ v_vec)
    ig_ext_vec, id_vec
end

function compute_incidence_matrix(ref::Dict)
    @unpack(ref, bus, branch, f_bus, t_bus)
    C = spzeros(Int, length(branch), length(bus))
    for (i, l) in enumerate(branch)
        fr = findfirst(bus .== f_bus[l])
        to = findfirst(bus .== t_bus[l])
        C[i,fr] = 1
        C[i,to] = -1
    end
    C
end

function compute_PTDF_matrix(ref::Dict)
    C = compute_incidence_matrix(ref)
    b_vec = [1 / ref["br_x"][l] for l in ref["branch"]]
    #b_vec = [ref["br_x"][l] / (ref["br_r"][l]^2 + ref["br_x"][l]^2) for l in ref["branch"]]
    diagm(b_vec) * C * inv(transpose(C) * diagm(b_vec) * C)
end

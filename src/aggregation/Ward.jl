function eliminate_bus!(Ybus,
        ig_vec::Array{Array{Complex{Float64},1},1},
        id_vec::Array{Complex{Float64},1},
        k::Int64)
    for j = 1:size(Ybus, 2), i = 1:size(Ybus, 1)
        if j != k && i != k
            Ybus[i,j] -= Ybus[i,k] * Ybus[k,j] / Ybus[k,k]
        end
    end
    for i = 1:length(ig_vec)
        if i != k
            ig_vec[i] -= Ybus[i,k] * ig_vec[k] / Ybus[k,k]
        end
    end
    for i = 1:length(id_vec)
        if i != k
            id_vec[i] -= Ybus[i,k] * id_vec[k] / Ybus[k,k]
        end
    end
    Ybus[k,:] = 0
    Ybus[:,k] = 0
    ig_vec[k] = [0,0,0]
    id_vec[k] = 0
end

#for each eqbus, select one bus as internal
#eliminate all remaining buses
#assign pd, qd from internal bus to eqbus


"""
Deduce eqbranch and eqbus parameters from a reduced Ybus, so that the Ybus of the
equivalent system is equal to the reduced one. Line charging susceptances
are assumed to be zero, just because it makes life easier.
"""
function Ward_extract_addmitance_matrix_parameters!(
        dst::Dict,
        src::Dict,
        Ybus;
        solver = IpoptSolver()
    )
    @unpack_with_suffix(src, 0, bus)
    @unpack(dst, branch, bus, f_bus, t_bus, bus0_bus, bus_internalbus0)
    br_r = Dict{String, Float64}()
    br_x = Dict{String, Float64}()
    br_b = Dict{String, Float64}(l => 0 for l in branch)
    tap = Dict{String, Float64}()
    shift = Dict{String, Float64}()
    gs = Dict{String, Float64}()
    bs = Dict{String, Float64}()
    diagYtmp = spzeros(Complex{Float64}, length(bus0))
    for l in branch
        i = findfirst(bus0 .== bus_internalbus0[f_bus[l]])
        j = findfirst(bus0 .== bus_internalbus0[t_bus[l]])
        println(i, " ", j)
        frr = -real(Ybus[i,j])
        fri = -imag(Ybus[i,j])
        tor = -real(Ybus[j,i])
        toi = -imag(Ybus[j,i])
        m = Model(solver = solver)
        @variable(m, tr, start = 1)
        @variable(m, ti, start = 0)
        @variable(m, g >= 0, start = frr)
        @variable(m, b, start = fri)
        @constraint(m, tr * frr - ti * fri - g == 0)
        @constraint(m, tr * tor + ti * toi - g == 0)
        @constraint(m, tr * fri + ti * frr - b == 0)
        @constraint(m, tr * toi - ti * tor - b == 0)
        @constraint(m, b^2 >= 1e-3)
        status = solve(m)
        status != :Optimal && print_with_color(:red, "could not determine ac equivalent branch parameters!\n")
        br_r[l] = r = real(1 / (getvalue(g) + im * getvalue(b)))
        br_x[l] = x = imag(1 / (getvalue(g) + im * getvalue(b)))
        tap[l] = t = abs(getvalue(tr) + im * getvalue(ti))
        shift[l] = s = angle(getvalue(tr) + im * getvalue(ti))
        y = 1 / (r + im * x)
        a = t * (cos(s) + im * sin(s))
        diagYtmp[i] += y / a^2
        diagYtmp[j] += y
    end
    for z in bus
        i = findfirst(bus0 .== bus_internalbus0[z])
        gs[z] = real(Ybus[i,i] - diagYtmp[i])
        bs[z] = imag(Ybus[i,i] - diagYtmp[i])
    end
    @pack(dst, br_r, br_x, br_b, tap, shift, gs, bs)
end

function Ward_extract_current_vectors_parameters!(
        dst::Dict,
        src::Dict,
        ig_vec,
        id_vec
    )
    @unpack_with_suffix(src, 0, bus, vm, va)
    @unpack(dst, bus, bus0_bus, bus_internalbus0)
    pg = Dict{String, Float64}()
    qg = Dict{String, Float64}()
    pmin = Dict{String, Float64}()
    qmin = Dict{String, Float64}()
    pmax = Dict{String, Float64}()
    qmax = Dict{String, Float64}()
    pd = Dict{String, Float64}()
    qd = Dict{String, Float64}()
    for z in bus
        i = findfirst(bus0 .== bus_internalbus0[z])
        v = vm0[z] * (cos(va0[z]) + im * sin(va0[z]))
        pg[z] = real(ig_vec[i][1] * v)
        qg[z] = -imag(ig_vec[i][1] * v)
        pmin[z] = real(ig_vec[i][2] * v)
        qmin[z] = -imag(ig_vec[i][2] * v)
        pmax[z] = real(ig_vec[i][3] * v)
        qmax[z] = -imag(ig_vec[i][3] * v)
        pd[z] = real(id_vec[i] * v)
        qd[z] = -imag(id_vec[i] * v)
    end
    gen = bus
    gen_bus = Dict(z => z for z in bus)
    @pack(dst, pg, qg, pd, pmin, qmin, pmax, qmax, qd, gen, gen_bus)
end

function Ward_aggregate_branches!(dst::Dict, src::Dict, Ybus)
    branch = Array{String,1}()
    branch0_branch = Dict{String,String}()
    f_bus = Dict{String,String}()
    t_bus = Dict{String,String}()
    flowdir0 = Dict{String,Any}()
    k = 1
    @unpack_with_suffix(src, 0, branch, bus, f_bus, t_bus)
    @unpack(dst, bus, bus0_bus)
    for j = 1:size(Ybus, 2), i = 1:size(Ybus, 1)
        if i < j && Ybus[i,j] != 0  #reduced Ybus keeps the symmetric pattern, so 'i < j' is good enough
            bus_a = bus0_bus[bus0[i]]
            bus_b = bus0_bus[bus0[j]]
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
    @pack(dst, branch, branch0_branch, f_bus, t_bus, flowdir0)
end

function Ward_compute_reduced_network(dst::Dict, src::Dict)
    @unpack_with_suffix(src, 0, bus)
    @unpack(dst, bus, bus0_bus, bus0_weight, bus_internalbus0)
    int_bus_id = findin(bus0, values(bus_internalbus0))
    Ybus = compute_admittance_matrix(src)
    ig_vec, id_vec = compute_current_vectors(src)
    for k in setdiff(eachindex(bus0), int_bus_id)
        eliminate_bus!(Ybus, ig_vec, id_vec, k)
    end
    Ybus, ig_vec, id_vec
end


function Ward_aggregate!(dst::Dict, src::Dict, m::Int = 4)
    assignments, costs = Spine.PTDF_bus_clustering(src, m)
    Ward_aggregate!(dst, src, assignments, costs)
end

function Ward_aggregate!(dst::Dict, src::Dict, assignments::Vector{Int}, costs::Vector{Float64})
    aggregate_buses!(dst, src, assignments, costs)
    aggregate_basic_bus_params!(dst, src)
    run_ac_pf!(src)
    Ybus, ig_vec, id_vec = Ward_compute_reduced_network(dst, src)
    Ward_aggregate_branches!(dst, src, Ybus)
    aggregate_basic_ac_branch_params!(dst, src)
    Ward_extract_addmitance_matrix_parameters!(dst, src, Ybus)
    Ward_extract_current_vectors_parameters!(dst, src, ig_vec, id_vec)
end

println("Loading pkgs...")
# Load required packaes
using Revise
using SpineModel
using JuMP
using Clp

## Extend/override SpineModel.jl
"""
    generate_variable_trans(m::Model)

Generates transmissions `trans` for each existing tuple of [connection,node_i,node_j].
For each `connection` between to `nodes`, two `trans` variables exist.
"""
function SpineModel.generate_variable_trans(m::Model)
    @butcher Dict{Tuple, JuMP.VariableRef}(
        (c, i, j, t) => @variable(
            m, base_name="trans[$c, $i, $j, $t]"
        ) for (c, i, j) in connection__node__node(), t=1:number_of_timesteps(time=:timer)
    )
end


"""
    generate_variable_storage(m::Model)

Generated `storage` variables for each existing tuple of `unit__commodity`,
if `storage_capacity` is specified.
Set the initial and final levels if specified.
"""
function generate_variable_storage(m::Model)
    storage = Dict{Tuple, JuMP.VariableRef}()
    for (u, c) in unit__commodity()
        storage_capacity(unit=u, commodity=c) != nothing || continue
        for t=0:number_of_timesteps(time=:timer)
            storage[u, c, t] = @variable(
                m,
                base_name="storage[$u, $c, $t]",
                lower_bound=0,
                upper_bound=storage_capacity(unit=u, commodity=c)
            )
        end
        # Fix the corresponding variable to the initial and final storage
        if initial_storage_factor(unit=u, commodity=c) != nothing
            JuMP.fix(
                storage[u, c, 0],
                initial_storage_factor(unit=u, commodity=c) * storage_capacity(unit=u, commodity=c);
                force=true)
        end
        if final_storage_factor(unit=u, commodity=c) != nothing
            JuMP.fix(
                storage[u, c, number_of_timesteps(time=:timer)],
                final_storage_factor(unit=u, commodity=c) * storage_capacity(unit=u, commodity=c);
                force=true)
        end
    end
    storage
end


function constraint_unit_storage_balance(m::Model, flow, storage)
    for (u, c) in unit__commodity(), t=1:number_of_timesteps(time=:timer)
        storage_capacity(unit=u, commodity=c) != nothing || continue
        @constraint(
            m,
            + sum(flow[c, n, u, :out, t]
                for n in commodity__node__unit__direction(commodity=c, unit=u, direction=:out))
            + storage[u, c, t]
            ==
            + sum(flow[c, n, u, :in, t]
                for n in commodity__node__unit__direction(commodity=c, unit=u, direction=:in))
            + storage[u, c, t - 1]
        )
    end
end


"""
    constraint_trans_delay(m::Model, trans)

Setup a delay on the transfer over a connection.
The parameter `trans_delay(...)` specifies the delay in multiples of the time step.
For example, a value of 2.5 means a delay of two and a half hours if the time step is one hour.
In practical terms, the above means that what enters the unit at a certain moment is only seen at
the output 2.5 time steps later.

In order to write the constraint, the value of the delay is split into integer and decimal parts.
"""
function constraint_trans_delay(m::Model, trans)
    for (conn, i, j) in connection__node__node(), t=1:number_of_timesteps(time=:timer)
        (trans_delay(connection=conn, node1=i, node2=j) != nothing) || continue
        (avg_trans(connection=conn, node1=i, node2=j) != nothing) || continue
        # Split delay into integer and decimal parts
        int_trans_delay = Int(floor(trans_delay(connection=conn, node1=i, node2=j)))
        dec_trans_delay = trans_delay(connection=conn, node1=i, node2=j) - int_trans_delay
        if t <= int_trans_delay
            # Before the integer part of the delay is elapsed, we get the average trans
            @constraint(
                m,
                - trans[conn, j, i, t]
                ==
                + avg_trans(connection=conn, node1=i, node2=j)
            )
        elseif t == int_trans_delay + 1
            # During the time-step next to when the integer part of the delay is elapsed,
            # we keep getting the average trans during the decimal part of the delay,
            # and then we get start getting what entered at the first time step
            @constraint(
                m,
                - trans[conn, j, i, t]
                ==
                + dec_trans_delay
                    * avg_trans(connection=conn, node1=i, node2=j)
                + (1.0 - dec_trans_delay)
                    * trans[conn, i, j, 1]
            )
        else
            # After the integer part of the delay is elapsed...
            @constraint(
                m,
                - trans[conn, j, i, t]
                ==
                + dec_trans_delay
                    * trans[conn, i, j, t - int_trans_delay - 1]
                + (1.0 - dec_trans_delay)
                    * trans[conn, i, j, t - int_trans_delay]
            )
        end
    end
end


"""
    constraint_nodal_balance(m::Model, flow, trans)

Enforce balance of all commodity flows from and to a node.
TODO: for electrical lines this constraint is obsolete unless
a trade based representation is used.
"""
function SpineModel.constraint_nodal_balance(m::Model, flow, trans)
    @butcher for n in node(), t=1:number_of_timesteps(time=:timer)
        if demand(node=n, t=t) != nothing
            @constraint(
                m,
                + sum(flow[c, n, u, :out, t] for (c, u) in commodity__node__unit__direction(node=n, direction=:out))
                ==
                + demand(node=n, t=t)
                + sum(flow[c, n, u, :in, t] for (c, u) in commodity__node__unit__direction(node=n, direction=:in))
                + sum(trans[k, n, j, t] for (k, j) in connection__node__node(node1=n))
            )
        else
            @constraint(
                m,
                + sum(flow[c, n, u, :out, t] for (c, u) in commodity__node__unit__direction(node=n, direction=:out))
                ==
                + sum(flow[c, n, u, :in, t] for (c, u) in commodity__node__unit__direction(node=n, direction=:in))
                + sum(trans[k, n, j, t] for (k, j) in connection__node__node(node1=n))
            )
        end
    end
end


"""
    constraint_trans_cap(m::Model, trans)

Limit flow capacity of a commodity transfered between to nodes in a
specific direction `node1 -> node2`.
"""
function SpineModel.constraint_trans_cap(m::Model, trans)
    for (conn, i, j) in connection__node__node(), t=1:number_of_timesteps(time=:timer)
        all([
            trans_cap_av_frac(connection=conn, node1=i, node2=j, t=t) != nothing,
            trans_cap(connection=conn) != nothing
        ]) || continue
        @constraint(
            m,
            + (trans[conn, i, j, t])
            <=
            + trans_cap_av_frac(connection=conn, node1=i, node2=j, t=t)
                * trans_cap(connection=conn)
        )
    end
end

# Export contents of database into the current session
println("Reading data...")
db_url = "sqlite:///hydro_data.sqlite"
JuMP_all_out(db_url)
println("Building model...")
# Init model
m = Model(with_optimizer(Clp.Optimizer))
# Create decision variables
flow = generate_variable_flow(m)
trans = generate_variable_trans(m)
storage = generate_variable_storage(m)
# Create objective function
objective_minimize_production_cost(m, flow)
# Add constraints
constraint_fix_ratio_out_in_flow(m, flow)
constraint_nodal_balance(m, flow, trans)
constraint_flow_capacity(m, flow)
constraint_trans_delay(m, trans)
constraint_trans_cap(m, trans)
constraint_unit_storage_balance(m, flow, storage)
# Run model
println("Solving model...")
optimize!(m)
status = termination_status(m)
println("Saving results...")
if status == MOI.OPTIMAL
    db_url_out = "sqlite:///hydro_data_out.sqlite"
    JuMP_results_to_spine_db!(db_url_out, db_url; upgrade=true, flow=flow, trans=trans, storage=storage)
end

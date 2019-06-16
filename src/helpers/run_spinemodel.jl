#############################################################################
# Copyright (C) 2017 - 2018  Spine Project
#
# This file is part of Spine Model.
#
# Spine Model is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Spine Model is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#############################################################################
"""
    run_spinemodel(
        url;
        optimizer=Cbc.Optimizer,
        cleanup=true,
        extend=m->nothing,
        result=""
    )

Run the Spine model from `url` and write results to the same `url`.
Keyword arguments have the same purpose as for [`run_spinemodel`](@ref).
"""
function run_spinemodel(
        url::String; optimizer=Cbc.Optimizer, cleanup=true, extend=m->nothing, result=""
    )
    run_spinemodel(
        url, url;
        optimizer=optimizer, cleanup=cleanup, extend=extend, result=result
    )
end

"""
    run_spinemodel(
        url_in, url_out;
        optimizer=Cbc.Optimizer,
        cleanup=true,
        extend=m->nothing,
        result=""
    )

Run the Spine model from `url_in` and write results to `url_out`.
At least `url_in` must point to valid Spine database.
A new Spine database is created at `url_out` if it doesn't exist.

# Optional keyword arguments

**`optimizer`** is the constructor of the optimizer used for building and solving the model.

**`cleanup`** tells [`run_spinemodel`](@ref) whether or not convenience function callables should be
set to `nothing` after completion.

**`extend`** is a function for extending the model. [`run_spinemodel`](@ref) calls this function with
the internal `JuMP.Model` object before calling `JuMP.optimize!`.

**`result`** is the name of the result object to write to `url_out` when saving results.
An empty string (the default) gets replaced by `"result"` with the current time appended.
"""
function run_spinemodel(
        url_in::String, url_out::String;
        optimizer=Cbc.Optimizer, cleanup=true, extend=m->nothing, result=""
    )
    printstyled("Creating convenience functions...\n"; bold=true)
    @time begin
        using_spinedb(url_in; upgrade=true)
    end
    printstyled("Creating temporal structure...\n"; bold=true)
    @time begin
        generate_time_slice()
        generate_time_slice_relationships()
    end
    printstyled("Initializing model...\n"; bold=true)
    @time begin
        m = Model(with_optimizer(optimizer))
        m.ext[:variables] = Dict{Symbol,Dict}()
        m.ext[:constraints] = Dict{Symbol,Dict}()
        # Create decision variables
        variable_flow(m)
        variable_units_on(m)
        variable_units_available(m)
        variable_units_started_up(m)
        variable_units_shut_down(m)
        variable_trans(m)
        variable_stor_state(m)
        ## Create objective function
        objective_minimize_total_discounted_costs(m)
        # Add constraints
    end
    printstyled("Generating constraints...\n"; bold=true)
    @time begin
        println("[constraint_flow_capacity]")
        @time constraint_flow_capacity(m)
        println("[constraint_fix_ratio_out_in_flow]")
        @time constraint_fix_ratio_out_in_flow(m)
        println("[constraint_max_ratio_out_in_flow]")
        @time constraint_max_ratio_out_in_flow(m)
        println("[constraint_min_ratio_out_in_flow]")
        @time constraint_min_ratio_out_in_flow(m)
        println("[constraint_fix_ratio_out_out_flow]")
        @time constraint_fix_ratio_out_out_flow(m)
        println("[constraint_max_ratio_out_out_flow]")
        @time constraint_max_ratio_out_out_flow(m)
        println("[constraint_fix_ratio_in_in_flow]")
        @time constraint_fix_ratio_in_in_flow(m)
        println("[constraint_max_ratio_in_in_flow]")
        @time constraint_max_ratio_in_in_flow(m)
        println("[constraint_fix_ratio_out_in_trans]")
        @time constraint_fix_ratio_out_in_trans(m)
        println("[constraint_max_ratio_out_in_trans]")
        @time constraint_max_ratio_out_in_trans(m)
        println("[constraint_min_ratio_out_in_trans]")
        @time constraint_min_ratio_out_in_trans(m)
        println("[constraint_trans_capacity]")
        @time constraint_trans_capacity(m)
        println("[constraint_nodal_balance]")
        @time constraint_nodal_balance(m)
        println("[constraint_max_cum_in_flow_bound]")
        @time constraint_max_cum_in_flow_bound(m)
        println("[constraint_stor_capacity]")
        @time constraint_stor_capacity(m)
        println("[constraint_stor_state]")
        @time constraint_stor_state(m)
        println("[constraint_units_on]")
        @time constraint_units_on(m)
        println("[constraint_units_available]")
        @time constraint_units_available(m)
        println("[constraint_minimum_operating_point]")
        @time constraint_minimum_operating_point(m)
        println("[constraint_min_down_time]")
        @time constraint_min_down_time(m)
        println("[constraint_min_up_time]")
        @time constraint_min_up_time(m)
        println("[constraint_unit_state_transition]")
        @time constraint_unit_state_transition(m)
        println("[extend]")
        @time extend(m)
    end
    # Run model
    printstyled("Solving model...\n"; bold=true)
    @time optimize!(m)
    status = termination_status(m)
    if status == MOI.OPTIMAL
        println("Optimal solution found")
        println("Objective function value: $(objective_value(m))")
        printstyled("Writing results to the database...\n"; bold=true)
        @fetch flow, units_started_up, units_shut_down, units_on, trans, stor_state = m.ext[:variables]
        # @fetch flow_capacity = m.ext[:constraints]
        @time write_results(
             url_out;
             result=result,
             flow=pack_time_series(SpineModel.value(flow)),
             units_started_up=pack_time_series(SpineModel.value(units_started_up)),
             units_shut_down=pack_time_series(SpineModel.value(units_shut_down)),
             units_on=pack_time_series(SpineModel.value(units_on)),
             trans=pack_time_series(SpineModel.value(trans)),
             stor_state=pack_time_series(SpineModel.value(stor_state)),
             # constraint_flow_capacity=pack_time_series(formulation(flow_capacity))
        )
    end
    printstyled("Done.\n"; bold=true)
    cleanup && notusing_spinedb(url_in)
    m
end

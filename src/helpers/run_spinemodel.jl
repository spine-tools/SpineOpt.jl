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
    run_spinemodel(db_url; optimizer=Cbc.Optimizer, cleanup=true, extend_model=m->nothing)

Run the Spine model from `db_url` and write results to the same url.
"""
# TODO: explain kwargs
function run_spinemodel(
        db_url::String; optimizer=Cbc.Optimizer, cleanup=true, extend_model=m->nothing, result_name=""
    )
    run_spinemodel(
        db_url, db_url;
        optimizer=optimizer, cleanup=cleanup, extend_model=extend_model, result_name=result_name
    )
end

"""
    run_spinemodel(db_url_in, db_url_out; optimizer=Cbc.Optimizer, cleanup=true, extend_model=m->nothing)

Run the Spine model from `db_url_in` and write results to `db_url_out`.
"""
function run_spinemodel(
        db_url_in::String, db_url_out::String;
        optimizer=Cbc.Optimizer, cleanup=true, extend_model=m->nothing, result_name=""
    )
    printstyled("Creating convenience functions...\n"; bold=true)
    @time using_spinedb(db_url_in; upgrade=true)
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
        # Unit capacity
        constraint_flow_capacity(m)
        # Ratio of in/out flows of a unit
        constraint_fix_ratio_out_in_flow(m)
        constraint_max_ratio_out_in_flow(m)
        constraint_min_ratio_out_in_flow(m)
        # Ratio of out/out flows of a unit
        constraint_fix_ratio_out_out_flow(m)
        constraint_max_ratio_out_out_flow(m)
        # Ratio of in/in flows of a unit
        constraint_fix_ratio_in_in_flow(m)
        constraint_max_ratio_in_in_flow(m)
        # Transmission losses
        constraint_fix_ratio_out_in_trans(m)
        constraint_max_ratio_out_in_trans(m)
        constraint_min_ratio_out_in_trans(m)
        # Transmission delays
        constraint_fix_delay_out_in_trans(m)
        # Transmission line capacity
        constraint_trans_capacity(m)
        # Nodal balance
        constraint_nodal_balance(m)
        # Absolute bounds on commodities
        constraint_max_cum_in_flow_bound(m)
        # Storage capacity
        constraint_stor_capacity(m)
        # Storage state balance equation
        constraint_stor_state(m)
        # Unit state
        constraint_units_on(m)
        constraint_units_available(m)
        constraint_minimum_operating_point(m)
        constraint_min_down_time(m)
        constraint_min_up_time(m)
        constraint_unit_state_transition(m)
        extend_model(m)
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
             db_url_out;
             result_name=result_name,
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
    cleanup && notusing_spinedb(db_url_in)
    m
end

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
function run_spinemodel(db_url_in::String, db_url_out::String; optimizer=Clp.Optimizer)
    printstyled("Creating convenience functions...\n"; bold=true)
    @time using_spinemodeldb(db_url_in; upgrade=true)
    printstyled("Creating temporal structure...\n"; bold=true)
    @time begin
        generate_time_slice()
        generate_time_slice_relationships()
    end
    printstyled("Initializing model...\n"; bold=true)
    @time begin
        m = Model(with_optimizer(optimizer))
        m.ext[:variables] = Dict{Symbol,VariableDict}()
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
        # Transmission losses
        constraint_fix_ratio_out_in_trans(m)
        constraint_max_ratio_out_in_trans(m)
        constraint_min_ratio_out_in_trans(m)
        # Transmission line capacity
        #constraint_trans_capacity(m)
        # Nodal balance
        constraint_nodal_balance(m)
        # Absolute bounds on commodities
        constraint_max_cum_in_flow_bound(m)
        # storage capacity
        constraint_stor_capacity(m)
        # storage state balance equation
        constraint_stor_state_init(m)
        constraint_stor_state(m)

        constraint_units_on(m)
        constraint_units_available(m)
        constraint_minimum_operating_point(m)
        constraint_min_down_time(m)
        constraint_min_up_time(m)
        constraint_commitment_variables(m)
        # needed: set/group of unitgroup CHP and Gasplant
    end
    # Run model
    printstyled("Solving model...\n"; bold=true)
    @time optimize!(m)
    status = termination_status(m)
    if status == MOI.OPTIMAL
        println("Optimal solution found")
        println("Objective function value: $(objective_value(m))")
        printstyled("Writing results to the database...\n"; bold=true)
        @fetch flow, units_started_up, units_shut_down, units_on = m.ext[:variables]
        @time write_results(
             db_url_out;
             flow=pack_trailing_dims(SpineModel.value(flow), 1),
             units_started_up=pack_trailing_dims(SpineModel.value(units_started_up), 1),
             units_shut_down=pack_trailing_dims(SpineModel.value(units_shut_down), 1),
             units_on=pack_trailing_dims(SpineModel.value(units_on), 1),
             #trans=pack_trailing_dims(SpineModel.value(trans), 1),
             #stor_state=pack_trailing_dims(SpineModel.value(stor_state), 1),
        )
    end
    printstyled("Done.\n"; bold=true)
    m
end

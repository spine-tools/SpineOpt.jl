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
    # Export contents of database into the current session
    # Init model
    printstyled("Initializing model...\n"; bold=true)
    @time begin
        m = Model(with_optimizer(optimizer))
        # Create decision variables
        flow = variable_flow(m)
        units_online = variable_units_online(m)
        trans = variable_trans(m)
        stor_state = variable_stor_state(m)
        ## Create objective function
        objective_minimize_total_discounted_costs(m, flow)
        # Add constraints
    end
    printstyled("Generating constraints...\n"; bold=true)
    @time begin
        # Unit capacity
        constraint_flow_capacity(m, flow)
        # Ratio of in/out flows of a unit
        constraint_fix_ratio_out_in_flow(m, flow)
        # Transmission losses
        #constraint_trans_loss(m, trans)
        constraint_fix_ratio_out_in_trans(m, trans)
        # Transmission line capacity
        #constraint_trans_capacity(m, trans)
        # Nodal balance
        constraint_nodal_balance(m, flow, trans)
        # Absolute bounds on commodities
        constraint_max_cum_in_flow_bound(m, flow)
        # storage capacity
        constraint_stor_capacity(m,stor_state)
        # storage state balance equation
        constraint_stor_state_init(m, stor_state)
        constraint_stor_state(m, stor_state,trans,flow)
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
        @time write_results(
            db_url_out;
            flow=pack_trailing_dims(SpineModel.value(flow), 1),
            #trans=pack_trailing_dims(SpineModel.value(trans), 1),
            #stor_state=pack_trailing_dims(SpineModel.value(stor_state), 1),
        )
    end
    printstyled("Done.\n"; bold=true)
    m, flow, trans, stor_state, units_online
end

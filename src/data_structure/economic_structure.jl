#############################################################################
# Copyright (C) 2017 - 2018  Spine Project
#
# This file is part of SpineOpt.
#
# SpineOpt is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# SpineOpt is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#############################################################################


# API
"""
    generate_economic_structure!(m::Model)
"""
function generate_economic_structure!(m::Model)
    generate_unit_CPT!(m::Model)

end




"""
    generate_unit_CPT()

Generate CPT factors for units that can be invested in.
"""
function generate_unit_CPT!(m::Model)
    instance = m.ext[:instance]
    dynamic_invest = dynamic_investments(model=instance)

    CPT = Dict()
    if dynamic_invest
        for u in unit()
            LT = lead_time(unit=u)
            TLIFE = unit_investment_tech_lifetime(unit=u)
            investment_block = first(unit__investment_temporal_block(unit=u))
            #time_slice function, keyword tempora
            for vintage_t in time_slice(m; temporal_block = investment_block)
                vintage_t_start = start(vintage_t)
                start_of_operation = vintage_t_start + LT
                end_of_operation = vintage_t_start + LT + TLIFE
                for t in time_slice(m; temporal_block = investment_block)
                    t_start = start(t)
                    t_end = end_(t)
                    dur =  t_end - t_start
                    if t_end < start_of_operation
                        val=0
                    elseif t_start<start_of_operation && start_of_operation<=t_end
                        val = max(min(1-(start_of_operation-t_start)/dur,1),0)
                    else
                        val = max(min((end_of_operation-t_start)/dur,1),0)
                    end
                    CPT[(u, vintage_t, t)] =  parameter_value(val)
                end
            end
        end
    else
        for u in unit()
            investment_block = first(unit__investment_temporal_block(unit=u))
            for vintage_t in time_slice(m; temporal_block = investment_block)
                for t in time_slice(m; temporal_block = investment_block)
                    CPT[(u, vintage_t, t)] = parameter_value(1.0)
                end
            end
        end
    end

    # unit_CPT_cls = RelationshipClass(
    #  :unit_CPT_cls,
    #  [:unit, :TimeSlice1, :TimeSlice2],
    #  [(unit=u, TimeSlice1=t1, TimeSlice2=t2 ) for (u, t1, t2) in keys(CPT)],
    #  CPT
    # )
    # unit_capacity_transfer = Parameter(:unit_capacity_transfer, [unit_CPT_cls])
    #
    #
    # for u in unit()
    #     investment_block = first(unit__investment_temporal_block(unit=u))
    #     for vintage_t in time_slice(m; temporal_block = investment_block)
    #         for t in time_slice(m; temporal_block = investment_block)
    #             println(unit_capacity_transfer[(unit = u, TimeSlice1= vintage_t, Timeslice2= t)])
    #         end
    #     end
    # end


end

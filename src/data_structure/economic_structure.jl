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
    generate_unit_annuity!(m::Model)
    generate_salvage_fraction!(m::Model)
    generate_tech_discount_factor!(m::Model)
    generate_discount_timeslice_duration!(m::Model)

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




"""
    generate_unit_annuity()

Generate annuity factors for units that can be invested in.
"""
function generate_unit_annuity!(m::Model)
    instance = m.ext[:instance]
    dynamic_invest = dynamic_investments(model=instance)
    discount_rate = discount_rate(model=instance)
    discount_year = discount_year(model=instance)

    annuity = Dict()

    for u in unit()
        LT = lead_time(unit=u)
        ELIFE = unit_investment_econ_lifetime(unit=u)
        CRF = discount_rate * (1+discount_rate)^ELIFE/((1+discount_rate)^ELIFE-1)
        investment_block = first(unit__investment_temporal_block(unit=u))
        #time_slice function, keyword tempora
        for vintage_t in time_slice(m; temporal_block = investment_block)
            vintage_t_start = start(vintage_t)
            start_of_operation = vintage_t_start + LT
            end_of_operation = vintage_t_start + LT + ELIFE
            if dynamic_invest
                j = vintage_t_start
                val = 0
                while j<= end_of_operation
                    UP = min(start_of_operation-1, j)
                    DOWN = max(vintage_t_start,j-ELIFE+1)
                    pfrac = max((UP-DOWN+1)/LT,0)
                    val+= pfrac *1/(1+discount_rate)^(j-discount_year)
                    j+= Year(1)
                end
            else
                j = vintage_t_start-LT
                val = 0
                while j<= end_of_operation-LT
                    UP = min(vintage_t_start-1, j)
                    DOWN = max(vintage_t_start-LT,j-ELIFE+1)
                    pfrac = max((UP-DOWN+1)/LT,0)
                    val+= pfrac *1/(1+discount_rate)^(j-discount_year)
                    j+= Year(1)
                end
            end
            annuity[(u, vintage_t)] =  parameter_value(val*CRF)
        end
    end
end




"""
    generate_salvage_fraction()

Generate salvage fraction for units that can be invested in.
"""
function generate_salvage_fraction!(m::Model)
    instance = m.ext[:instance]
    dynamic_invest = dynamic_investments(model=instance)
    discount_rate = discount_rate(model=instance)
    discount_year = discount_year(model=instance)
    EOH = model_start(model=instance)

    salvage_fraction = Dict()

    for u in unit()
        LT = lead_time(unit=u)
        ELIFE = unit_investment_econ_lifetime(unit=u)
        investment_block = first(unit__investment_temporal_block(unit=u))
        #time_slice function, keyword tempora
        for vintage_t in time_slice(m; temporal_block = investment_block)
            vintage_t_start = start(vintage_t)
            start_of_operation = vintage_t_start + LT
            end_of_operation = vintage_t_start + LT + ELIFE
            if dynamic_invest
                j1= EOH
                j2 = vintage_t_start
                val1 = 0
                val2 = 0
                while j1<= end_of_operation
                    UP = min(start_of_operation-1, j1)
                    DOWN = max(vintage_t_start,j1-ELIFE+1)
                    pfrac = max((UP-DOWN+1)/LT,0)
                    val1+= pfrac *1/(1+discount_rate)^(j1-discount_year)
                    j1+= Year(1)
                end
                while j2<= end_of_operation
                    UP = min(start_of_operation-1, j2)
                    DOWN = max(vintage_t_start,j2-ELIFE+1)
                    pfrac = max((UP-DOWN+1)/LT,0)
                    val2+= pfrac *1/(1+discount_rate)^(j2-discount_year)
                    j2+= Year(1)
                end
            else
                j1 = EOH
                j2 = vintage_t_start-LT
                val1 = 0
                val2 = 0
                while j1<= end_of_operation-LT
                    UP = min(vintage_t_start-1, j1)
                    DOWN = max(vintage_t_start-LT,j1-ELIFE+1)
                    pfrac = max((UP-DOWN+1)/LT,0)
                    val+= pfrac *1/(1+discount_rate)^(j1-discount_year)
                    j1+= Year(1)
                end
                while j2<= end_of_operation-LT
                    UP = min(vintage_t_start-1, j2)
                    DOWN = max(vintage_t_start-LT,j2-ELIFE+1)
                    pfrac = max((UP-DOWN+1)/LT,0)
                    val2+= pfrac *1/(1+discount_rate)^(j2-discount_year)
                    j2+= Year(1)
                end
            end
            val = max(val1/val2,0)
            salvage_fraction[(u, vintage_t)] =  parameter_value(val)
        end
    end
end


"""
    generate_tech_discount_factor()

Generate technology-specific discount factors for units that can be invested in.
"""
function generate_tech_discount_factor!(m::Model)
    instance = m.ext[:instance]
    discount_rate = discount_rate(model=instance)
    tech_discount_factor = Dict()

    for u in unit()
        ELIFE = unit_investment_econ_lifetime(unit=u)
        tech_discount_rate = discount_rate(unit=u)
        CRF_model = discount_rate * (1+discount_rate)^ELIFE/((1+discount_rate)^ELIFE-1)
        CRF_tech = tech_discount_rate * (1+tech_discount_rate)^ELIFE/((1+tech_discount_rate)^ELIFE-1)
        val = CRF_tech/CRF_model
        tech_discount_factor[u] =  parameter_value(val)
    end
end




"""
    generate_discount_timeslice_duration()

Generate discounted duration of timeslices for each investment timeslice.
"""
function generate_discount_timeslice_duration!(m::Model)
    instance = m.ext[:instance]
    dynamic_invest = dynamic_investments(model=instance)
    discount_rate = discount_rate(model=instance)
    discount_year = discount_year(model=instance)

    discounted_duration = Dict()

    for u in unit()
        investment_block = first(unit__investment_temporal_block(unit=u))
        #time_slice function, keyword tempora
        for t in time_slice(m; temporal_block = investment_block)
            t_start = start(t)
            t_end = end(t)

            j = t_start
            val = 0
            while j< t_end
                val+= 1/(1+discount_rate)^(j-discount_year)
                j+= Year(1)
            end
            discounted_duration[(u, t)] =  parameter_value(val)
        end
    end
end

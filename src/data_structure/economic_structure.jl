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
    generate_unit_capacity_transfer_factor!(m::Model)
    generate_unit_annuity!(m::Model)
    generate_salvage_fraction!(m::Model)
    generate_tech_discount_factor!(m::Model)
    generate_discount_timeslice_duration!(m::Model)

end




"""
    generate_unit_capacity_transfer_factor()

Generate capacity_transfer_factor factors for units that can be invested in. The
unit_capacity_transfer_factor is a Map parameter that holds the fraction of an investment in a unit u during vintage
year t_v that is still available in year t.
"""
function generate_unit_capacity_transfer_factor!(m::Model)
    instance = m.ext[:instance]
    capacity_transfer_factor = Dict()
    if dynamic_investments(model=instance)
        for u in members(unit())
            #TODO: members, simply to not do this for the groups; make this more elgant?
            map_stoch_indices = [] #NOTE: will hold stochastic indices
            map_inner = [] #NOTE: will map values inside stochastic mapping
            for s in unique([x.stochastic_scenario for x in units_invested_available_indices(m;unit=u)])
                map_indices = []
                timeseries_array = []
                for (u,s,vintage_t) in units_invested_available_indices(m;unit=u, stochastic_scenario=s, t = Iterators.flatten((history_time_slice(m), time_slice(m))))
                    LT = lead_time(unit=u,stochastic_scenario=s,t=vintage_t)
                    TLIFE = unit_investment_tech_lifetime(unit=u,stochastic_scenario=s,t=vintage_t)
                    vintage_t_start = start(vintage_t)
                    start_of_operation = vintage_t_start + LT
                    end_of_operation = vintage_t_start + LT + TLIFE
                    timeseries_val = []
                    timeseries_ind = []
                    for t in time_slice(m; temporal_block = unit__investment_temporal_block(unit=u))
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
                        capacity_transfer_factor[(u, vintage_t.start.x, t.start.x)] =  parameter_value(val)
                        push!(timeseries_val,val)
                        push!(timeseries_ind,t_start)
                    end
                    push!(map_indices,vintage_t_start)
                    push!(timeseries_array,TimeSeries(timeseries_ind,timeseries_val,false,false))
                end
                push!(map_stoch_indices,s)
                push!(map_inner, SpineInterface.Map(map_indices,timeseries_array))
            end
            unit.parameter_values[u][:capacity_transfer_factor] = parameter_value(SpineInterface.Map(map_stoch_indices,map_inner))
            #NOTE: map_indices here will be stochastic_scenarios!
        end
    else
        for u in unit()
            investment_block = first(unit__investment_temporal_block(unit=u))
            map_indices = []
            timeseries_array = []
            for vintage_t in time_slice(m; temporal_block = investment_block)
                timeseries_val = []
                timeseries_ind = []
                for t in time_slice(m; temporal_block = investment_block)
                    t_start = start(t)
                    val = 1
                    push!(timeseries_val,val)
                    push!(timeseries_ind,t_start)
                end
                push!(map_indices,start(vintage_t))
                push!(timeseries_array,TimeSeries(timeseries_ind,timeseries_val,false,false))
            end
            unit.parameter_values[u][:capacity_transfer_factor] = parameter_value(SpineInterface.Map(map_indices,timeseries_array))
        end
    end
    capacity_transfer_factor = Parameter(:capacity_transfer_factor, [unit])
    @eval begin
        capacity_transfer_factor = $capacity_transfer_factor
    end
end




"""
    generate_unit_annuity()

Generate annuity factors for units that can be invested in.
"""
function generate_unit_annuity!(m::Model)
    instance = m.ext[:instance]
    discnt_rate = discount_rate(model=instance)
    discnt_year = discount_year(model=instance)
    annuity = Dict()
    for u in unit()
        stochastic_map_indices = []
        stochastic_map_vals = []
        for s in unique([x.stochastic_scenario for x in units_invested_available_indices(m)]) #NOTE: this is specific to lifetimes in years
            timeseries_ind = []
            timeseries_val = []
            for (u,s,vintage_t) in units_invested_available_indices(m;unit=u,stochastic_scenario=s)
                LT = lead_time(unit=u,stochastic_scenario=s,t=vintage_t)
                ELIFE = unit_investment_econ_lifetime(unit=u,stochastic_scenario=s,t=vintage_t)
                vintage_t_start = start(vintage_t)
                start_of_operation = vintage_t_start + LT
                end_of_operation = vintage_t_start + LT + ELIFE
                if dynamic_investments(model=instance)
                    j = vintage_t_start
                    val = 0
                    while j<= end_of_operation
                        val+= payment_fraction(vintage_t_start, j, ELIFE, LT)*discount_factor(instance,discnt_rate,j) #1/(1+discnt_rate)^((Year(j)-Year(discnt_year))/Year(1))
                        j+= Year(1)
                    end
                else
                    j = vintage_t_start-LT
                    val = 0
                    while j<= end_of_operation-LT
                        val+= payment_fraction(vintage_t_start, j, ELIFE, LT) *discount_factor(instance,discnt_rate,j)
                        j+= Year(1)
                    end
                end
                push!(timeseries_ind,start(vintage_t))
                push!(timeseries_val,val*capital_recovery_factor(instance, discnt_rate,ELIFE))
            end
            push!(stochastic_map_indices,s)
            push!(stochastic_map_vals,TimeSeries(timeseries_ind,timeseries_val,false,false))
        end
        unit.parameter_values[u][:annuity] = parameter_value(SpineInterface.Map(stochastic_map_indices,stochastic_map_vals))
    end
    annuity = Parameter(:annuity, [unit])
    @eval begin
        annuity = $annuity
    end
end


function capital_recovery_factor(m, discnt_rate ,ELIFE)
    if discnt_rate != 0
        capital_recovery_factor =  discnt_rate * 1/(discount_factor(m,discnt_rate,ELIFE)) * 1/(1/(discount_factor(m,discnt_rate,ELIFE))-1)
    else
        capital_recovery_factor = 1/(Year(ELIFE)/Year(1))
    end
    capital_recovery_factor
end

function discount_factor(m,discnt_rate,year::DateTime)
    discnt_year = discount_year(model=m)
    discnt_factor = 1/(1+discnt_rate)^((Year(year)-Year(discnt_year))/Year(1))
end

function discount_factor(m,discnt_rate,year::T) where {T<:Period}
    discnt_year = discount_year(model=m)
    discnt_factor = 1/(1+discnt_rate)^((Year(year))/Year(1))
end

"""
Fraction of the annuity for technology u with vintage year t_vintage that needs to be paid
in payment year t. Depends on leadtime and economic lifetime of u.
"""
function payment_fraction(t_vintage, t, t_econ_life, t_lead)
    UP = min(t_vintage + t_lead -Year(1), t)
    DOWN = max(t_vintage,t-t_econ_life+Year(1))
    pfrac = max((Year(UP)-Year(DOWN)+Year(1))/t_lead,0)
end

"""
    generate_salvage_fraction()

Generate salvage fraction for units that can be invested in.
"""
function generate_salvage_fraction!(m::Model)
    instance = m.ext[:instance]
    discnt_rate = discount_rate(model=instance)
    discnt_year = discount_year(model=instance)
    EOH = model_end(model=instance)

    salvage_fraction = Dict()

    for u in unit()
        stochastic_map_ind = []
        stochastic_map_val = []
        for s in unique([x.stochastic_scenario for x in units_invested_available_indices(m)])
            timeseries_ind = []
            timeseries_val = []
            LT = lead_time(unit=u)
            ELIFE = unit_investment_econ_lifetime(unit=u)
            investment_block = first(unit__investment_temporal_block(unit=u))
            for vintage_t in time_slice(m; temporal_block = investment_block)
                vintage_t_start = start(vintage_t)
                start_of_operation = vintage_t_start + LT
                end_of_operation = vintage_t_start + LT + ELIFE
                if dynamic_investments(model=instance)
                    j1= EOH + Year(1) #numerator +1 or not?
                    j2 = vintage_t_start
                    val1 = 0
                    val2 = 0
                    while j1<= end_of_operation
                        ## start_of_operation!
                        val1+= payment_fraction(vintage_t_start, j1, ELIFE, LT) *discount_factor(instance,discnt_rate,j1)
                        j1+= Year(1)
                    end
                    while j2<= end_of_operation
                        ## start_of_operation!
                        val2+= payment_fraction(vintage_t_start, j2, ELIFE, LT) *discount_factor(instance,discnt_rate,j2)
                        j2+= Year(1)
                    end
                else
                    j1 = EOH + Year(1) #TODO: check? + Year(1)
                    j2 = vintage_t_start-LT
                    val1 = 0
                    val2 = 0
                    while j1<= end_of_operation-LT
                        val1 += payment_fraction(vintage_t_start, j1, ELIFE, LT) *discount_factor(instance,discnt_rate,j1)
                        j1+= Year(1)
                    end
                    while j2<= end_of_operation-LT
                        val2+= payment_fraction(vintage_t_start, j2, ELIFE, LT) * discount_factor(instance,discnt_rate,j2)
                        j2+= Year(1)
                    end
                end
                val = max(val1/val2,0)
                push!(timeseries_ind,start(vintage_t))
                push!(timeseries_val,val)
            end
            push!(stochastic_map_ind,s)
            push!(stochastic_map_val,TimeSeries(timeseries_ind,timeseries_val,false,false))
        end
        unit.parameter_values[u][:salvage_fraction] = parameter_value(SpineInterface.Map(stochastic_map_ind,stochastic_map_val))
    end
    salvage_fraction = Parameter(:salvage_fraction, [unit])
    @eval begin
        salvage_fraction = $salvage_fraction
    end
end



"""
    generate_tech_discount_factor()

Generate technology-specific discount factors for units that can be invested in.
"""
function generate_tech_discount_factor!(m::Model)
    instance = m.ext[:instance]
    discnt_rate = discount_rate(model=instance)
    tech_discount_factor = Dict()
    for u in unit()
        if u in indices(discount_rate_technology_specific) #Default: 0
            stoch_map_val = []
            stoch_map_ind = []
            for s in stochastic_structure__stochastic_scenario(stochastic_structure=unit__investment_stochastic_structure(unit=u))
                ELIFE = unit_investment_econ_lifetime(unit=u,stochastic_scenario=s)
                tech_discount_rate = discount_rate_technology_specific(unit=u,stochastic_scenario=s)
                val = capital_recovery_factor(instance,tech_discount_rate,ELIFE)/capital_recovery_factor(instance,discnt_rate,ELIFE)
                push!(stoch_map_val,val)
                push!(stoch_map_ind,s)
            end
            unit.parameter_values[u][:tech_discount_factor] = parameter_value(SpineInterface.Map(stoch_map_ind,stoch_map_val))
        end
    end
    tech_discount_factor = Parameter(:tech_discount_factor, [unit])
    @eval begin
        tech_discount_factor = $tech_discount_factor
    end
end




"""
    generate_discount_timeslice_duration()

Generate discounted duration of timeslices for each investment timeslice.
"""
function generate_discount_timeslice_duration!(m::Model)
    #TODO: function arguments: objects class, $(objects class)____investment_stochastic_structure, $(objects class)__investment_temporal_block
    instance = m.ext[:instance]
    discnt_rate = discount_rate(model=instance)
    discnt_year = discount_year(model=instance)

    discounted_duration = Dict()

    for u in unit()
        stoch_map_val = []
        stoch_map_ind = []
        for s in stochastic_structure__stochastic_scenario(stochastic_structure=unit__investment_stochastic_structure(unit=u))
            timeseries_ind = []
            timeseries_val = []
            investment_block = first(unit__investment_temporal_block(unit=u)) #TODO generalize?
            for t in time_slice(m; temporal_block = investment_block)
                t_start = start(t)
                t_end = end_(t)
                j = t_start
                val = 0
                while j< t_end
                    val+= discount_factor(instance,discnt_rate,j)
                    j+= Year(1)
                end
                push!(timeseries_ind,start(t))
                push!(timeseries_val,val)
            end
            push!(stoch_map_ind,s)
            push!(stoch_map_val,TimeSeries(timeseries_ind,timeseries_val,false,false))
        end
        unit.parameter_values[u][:discounted_duration] = parameter_value(SpineInterface.Map(stoch_map_ind,stoch_map_val))
    end
    discounted_duration = Parameter(:discounted_duration, [unit])#,node])
    @eval begin
        discounted_duration = $discounted_duration
    end
end

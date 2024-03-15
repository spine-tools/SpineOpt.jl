#############################################################################
# Copyright (C) 2017 - 2026  Spine and Mopo Project
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


"""
    generate_economic_structure!(m::Model)
"""
function generate_economic_structure!(m::Model;log_level=3)
    for (obj, name) in [(unit,:unit),(node,:storage),(connection,:connection)]
        @timelog log_level 3 "- [Generated discounted durations for $(obj)s]" generate_discount_timeslice_duration!(m::Model,obj, name)
    end
    !isempty([
        model__default_investment_temporal_block()...,
        node__investment_temporal_block()...,
        unit__investment_temporal_block()...,
        connection__investment_temporal_block()...
    ]) || return
    for (obj, name) in [(unit,:unit),(node,:storage),(connection,:connection)]
        @timelog log_level 3 "- [Generated capacity transfer factors for $(name)s]" generate_capacity_transfer_factor!(m::Model,obj, name)
        @timelog log_level 3 "- [Generated conversion to discounted investments of $(name)s]" generate_conversion_to_discounted_annuities!(m::Model,obj, name)
        @timelog log_level 3 "- [Generated conversion for discounted decommissioning of $(name)s]" generate_decommissioning_conversion_to_discounted_annuities!(m::Model,obj, name)
        @timelog log_level 3 "- [Generated salvage fraction for $(name)s]" generate_salvage_fraction!(m::Model,obj, name)
        @timelog log_level 3 "- [Generated $(name) technology specific discount factors]" generate_tech_discount_factor!(m::Model,obj, name)

    end
end



"""
    generate_unit_capacity_transfer_factor()

Generate capacity_transfer_factor factors for units that can be invested in. The
unit_capacity_transfer_factor is a Map parameter that holds the fraction of an investment during vintage
year t_v in a unit u that is still available in the model year t.
"""
function generate_capacity_transfer_factor!(m::Model, obj_cls::ObjectClass, obj_name::Symbol)
    instance = m.ext[:spineopt].instance
    capacity_transfer_factor = Dict()
    investment_indices = eval(Symbol("$(obj_name)s_invested_available_indices"))
    lead_time = eval(Symbol("$(obj_name)_lead_time"))
    tech_lifetime = eval(Symbol("$(obj_name)_investment_tech_lifetime"))
    invest_temporal_block = eval(Symbol("$(obj_cls)__investment_temporal_block"))
    param_name = Symbol("$(obj_name)_capacity_transfer_factor")
    for id in invest_temporal_block(temporal_block=anything)
        if (!isnothing(tech_lifetime(;Dict(obj_cls.name=>id)...))
            || !(isnothing(lead_time(;Dict(obj_cls.name=>id)...)) || iszero(lead_time(;Dict(obj_cls.name=>id)...))))
            map_stoch_indices = [] #NOTE: will hold stochastic indices
            map_inner = [] #NOTE: will map values inside stochastic mapping
            for s in unique([x.stochastic_scenario for x in investment_indices(m;Dict(obj_cls.name => id)...)])
                map_indices = []
                timeseries_array = []
                for (u,s,vintage_t) in investment_indices(m;
                        Dict(
                            obj_cls.name => id,
                            :stochastic_scenario=>s,
                            :t => Iterators.flatten((history_time_slice(m), time_slice(m)))
                            )...
                        )
                    LT = lead_time(;Dict(obj_cls.name=>id,:stochastic_scenario=>s,:t=>vintage_t)...)
                    if isnothing(LT)
                        LT = Year(0)
                        #NOTE: In case LT is `none`, we will assume a duration of `0 Years`
                    end
                    TLIFE = tech_lifetime(;Dict(obj_cls.name=>id,:stochastic_scenario=>s,:t=>vintage_t)...)
                    if isnothing(TLIFE)
                        max(Year(last(time_slice(m)).start.x)-Year(first(time_slice(m)).end_.x),Year(1))
                        #NOTE: In case TLIFE is `none`, we assume that the unit exists until the end of the optimization
                    end
                    vintage_t_start = start(vintage_t)
                    start_of_operation = vintage_t_start + LT
                    end_of_operation = vintage_t_start + LT + TLIFE
                    timeseries_val = []
                    timeseries_ind = []
                    for t in time_slice(m; temporal_block = invest_temporal_block(;Dict(obj_cls.name=>id,)...),t = Iterators.flatten((history_time_slice(m), time_slice(m))))
                        t_start = start(t)
                        t_end = end_(t)
                        dur =  t_end - t_start
                        if t_end < start_of_operation
                            val = 0
                        #=NOTE:
                        if the end of the timeslice t is before the start of operation for a unit installed
                        at vntage year vintage_t_start => no capacity available yet at t_end=#
                        elseif t_start < start_of_operation
                            val = max(min(1-(start_of_operation-t_start)/dur,1),0)
                        #=NOTE:
                        if the end of timeslice t is after the start of operation and the start of the timeslice t
                        is before the start of operation, val will take a value between 0 and 1, depending on
                        how much of this capacity is available on average during t=#
                        else
                            val = max(min((end_of_operation-t_start)/dur,1),0)
                        #=NOTE:
                        in all other cases, val will describe the fraction [0,1] that is (still) available at
                        time step t. This will be 1, if the technology does not get decomissioned during t,
                        a fraction, if the technology gets decomssioned during t, and 0 for all other cases (fully decomissioned)
                        =#
                        end
                        capacity_transfer_factor[(id, vintage_t.start.x, t.start.x)] =  parameter_value(val)
                        push!(timeseries_val,val)
                        push!(timeseries_ind,t_start)
                    end
                    push!(map_indices,vintage_t_start)
                    push!(timeseries_array,TimeSeries(timeseries_ind,timeseries_val,false,false))
                end
                push!(map_stoch_indices,s)
                push!(map_inner, SpineInterface.Map(map_indices,timeseries_array))
            end
            obj_cls.parameter_values[id][param_name] = parameter_value(SpineInterface.Map(map_stoch_indices,map_inner))
            #NOTE: map_indices here will be stochastic_scenarios!
        else
            obj_cls.parameter_values[id][param_name] = parameter_value(1)
        end
    end
    @eval begin
        $(param_name) = $(Parameter(param_name, [obj_cls]))
    end
end




"""
    generate_conversion_to_discounted_annuities()

The conversion_to_discounted_annuities factor translates the overnight costs of an investment
into discounted (to the `dicount_year`) annual payments, distributed over the total
lifetime of the investment. Investment payments are assumed to increase linearly over the lead-time, and decrease
linearly towards the end of the economic lifetime.

"""
function generate_conversion_to_discounted_annuities!(m::Model, obj_cls::ObjectClass, obj_name::Symbol)
    instance = m.ext[:spineopt].instance
    discnt_year = discount_year(model=instance)
    conversion_to_discounted_annuities = Dict()
    investment_indices = eval(Symbol("$(obj_name)s_invested_available_indices"))
    lead_time = eval(Symbol("$(obj_name)_lead_time"))
    econ_lifetime = eval(Symbol("$(obj_name)_investment_econ_lifetime"))
    param_name = Symbol("$(obj_name)_conversion_to_discounted_annuities")
    for id in obj_cls()
        if (discount_rate(model=model()[1]) == 0 || isnothing(discount_rate(model=model()[1])))
            obj_cls.parameter_values[id][param_name] = parameter_value(1)
        else
            stochastic_map_indices = []
            stochastic_map_vals = []
            for s in unique([x.stochastic_scenario for x in investment_indices(m)]) #NOTE: this is specific to lifetimes in years
                timeseries_ind = []
                timeseries_val = []
                for (u,s,vintage_t) in investment_indices(m;Dict(obj_cls.name=>id,:stochastic_scenario=>s)...)
                    discnt_rate = discount_rate(model=instance, stichastic_scenario=s, t=vintage_t) #TODO time and stoch dependent
                    LT = lead_time(;Dict(obj_cls.name=>id,:stochastic_scenario=>s,:t=>vintage_t)...)
                    if isnothing(LT)
                        LT = Year(0)
                    end
                    ELIFE = econ_lifetime(;Dict(obj_cls.name=>id,:stochastic_scenario=>s,:t=>vintage_t)...)
                    vintage_t_start = start(vintage_t)
                    if isnothing(econ_lifetime(;Dict(obj_cls.name=>id)...))
                        ### if empty it should translate to discounted overnight costs
                        val = discount_factor(instance,discnt_rate,vintage_t_start)
                        push!(timeseries_ind,vintage_t_start)
                        push!(timeseries_val,val)
                    else
                        end_of_operation = vintage_t_start + LT + ELIFE
                        j = vintage_t_start
                        val = 0
                        while j<= end_of_operation
                            val+= payment_fraction(vintage_t_start, j, ELIFE, LT)*discount_factor(instance,discnt_rate,j) #1/(1+discnt_rate)^((Year(j)-Year(discnt_year))/Year(1))
                            j+= Year(1)
                        end
                        push!(timeseries_ind,start(vintage_t))
                        push!(timeseries_val,val*capital_recovery_factor(instance, discnt_rate,ELIFE))
                    end
                end
                push!(stochastic_map_indices,s)
                push!(stochastic_map_vals,TimeSeries(timeseries_ind,timeseries_val,false,false))
            end
            obj_cls.parameter_values[id][param_name] = parameter_value(SpineInterface.Map(stochastic_map_indices,stochastic_map_vals))
        end
    end
    @eval begin
        $(param_name) = $(Parameter(param_name, [obj_cls]))
    end
end

"""
    function capital_recovery_factor(m, discnt_rate ,ELIFE)

The `captial_recovery_factor` is the ratio between constant annuities and the present value of these annuities over the economic lifetime of the investment.
"""

function capital_recovery_factor(m, discnt_rate,ELIFE)
    if ELIFE.value==0
        ELIFE = Year(0)
    end
    if discnt_rate != 0
        capital_recovery_factor =  discnt_rate / (1+discnt_rate) * 1/(discount_factor(m,discnt_rate,ELIFE)) * 1/(1/(discount_factor(m,discnt_rate,ELIFE))-1)
    else
        capital_recovery_factor = 1/(Year(ELIFE)/Year(1))
    end
    capital_recovery_factor
end

"""
    function discount_factor(m,discnt_rate,year::DateTime)

The discount factor discounts payments at a certain timestep `t` to the models `discount_year`
"""

function discount_factor(m, discnt_rate, year::Union{DateTime})
    discnt_year = discount_year(model=m)
    if isnothing(discnt_year)
        discnt_year = Year(1)
    end
    discnt_factor = 1/(1+discnt_rate)^((Year(year)-Year(discnt_year))/Year(1))
end

function discount_factor(m,discnt_rate,year::Union{T, Nothing}) where {T<:Period}
    if year.value == 0
        year = Year(0)
    end
    discnt_factor = 1/(1+discnt_rate)^((Year(year))/Year(1))
end

"""
function payment_fraction(t_vintage, t, t_econ_life, t_lead)

`payment_fraction` for technology u with vintage year t_vintage that needs to be paid
in payment year t. Depends on leadtime and economic lifetime of u (assumed to increase linearly over leadtime, and decrease linearly towards the end of the economic lifetime).
"""
function payment_fraction(t_vintage, t, t_econ_life, t_lead)
    t_lead = t_lead.value == 0 ? Year(1) : t_lead
    UP = min(t_vintage + t_lead -Year(1), t)
    DOWN = max(t_vintage,t-t_econ_life+Year(1))
    pfrac = max((Year(UP)-Year(DOWN)+Year(1))/t_lead,0)
end

"""
    generate_salvage_fraction()

Generate salvage fraction of units, which exonomic lifetime exceeds the modeling horizon.
"""
function generate_salvage_fraction!(m::Model, obj_cls::ObjectClass, obj_name::Symbol)
    instance = m.ext[:spineopt].instance
    discnt_year = discount_year(model=instance)
    EOH = model_end(model=instance)
    salvage_fraction = Dict()
    econ_lifetime = eval(Symbol("$(obj_name)_investment_econ_lifetime"))
    investment_indices = eval(Symbol("$(obj_name)s_invested_available_indices"))
    lead_time = eval(Symbol("$(obj_name)_lead_time"))
    invest_temporal_block = eval(Symbol("$(obj_cls)__investment_temporal_block"))
    param_name = Symbol("$(obj_name)_salvage_fraction")
    for id in invest_temporal_block(temporal_block=anything)
        if id in indices(econ_lifetime)
            stochastic_map_ind = []
            stochastic_map_val = []
            for s in unique([x.stochastic_scenario for x in investment_indices(m)])
                timeseries_ind = []
                timeseries_val = []
                for vintage_t in time_slice(m; temporal_block = invest_temporal_block(;Dict(obj_cls.name=>id)...))
                    ELIFE = econ_lifetime(;Dict(obj_cls.name=>id, stochastic_scenario.name=>s,)...,t=vintage_t)
                    LT = lead_time(;Dict(obj_cls.name=>id, stochastic_scenario.name=>s,)...,t=vintage_t)
                    if isnothing(LT)
                        LT= Year(0)
                    end
                    discnt_rate = discount_rate(model=instance, stochastic_scenario=s,t=vintage_t) #TODO! scenario dependent and time
                    vintage_t_start = start(vintage_t)
                    start_of_operation = vintage_t_start + LT
                    end_of_operation = vintage_t_start + LT + ELIFE
                    j1= EOH #+ Year(1) #numerator +1 or not?
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
                    val2 == 0 ? val=0 : val = max(val1/val2,0)
                    push!(timeseries_ind,start(vintage_t))
                    push!(timeseries_val,val)
                end
                push!(stochastic_map_ind,s)
                push!(stochastic_map_val,TimeSeries(timeseries_ind,timeseries_val,false,false))
            end
            obj_cls.parameter_values[id][param_name] = parameter_value(SpineInterface.Map(stochastic_map_ind,stochastic_map_val))
        else
            obj_cls.parameter_values[id][param_name] = parameter_value(0)
        end
    end
    @eval begin
        $(param_name) = $(Parameter(param_name, [obj_cls]))
    end
end



"""
    generate_tech_discount_factor()

Generate technology-specific discount factors for investments (e.g., for risky investments).
"""
function generate_tech_discount_factor!(m::Model, obj_cls::ObjectClass, obj_name::Symbol)
    instance = m.ext[:spineopt].instance
    discnt_rate_tech = eval(Symbol("$(obj_name)_discount_rate_technology_specific"))
    econ_lifetime = eval(Symbol("$(obj_name)_investment_econ_lifetime"))
    invest_stoch_struct = eval(Symbol("$(obj_cls)__investment_stochastic_structure"))
    param_name = Symbol("$(obj_name)_tech_discount_factor")
    investment_indices = eval(Symbol("$(obj_name)s_invested_available_indices"))
    for id in obj_cls()
        if (!isnothing(discnt_rate_tech(;Dict(obj_cls.name => id)...))
            && discnt_rate_tech(;Dict(obj_cls.name => id)...) != 0
            && !isnothing(econ_lifetime(;Dict(obj_cls.name => id)...)))
            stoch_map_val = []
            stoch_map_ind = []
            for s in stochastic_structure__stochastic_scenario(stochastic_structure=invest_stoch_struct(;Dict(obj_cls.name => id)...))
                val = []
                for (u,s,vintage_t) in investment_indices(m;Dict(obj_cls.name=>id,:stochastic_scenario=>s)...)
                    ELIFE = econ_lifetime(;Dict(obj_cls.name => id, stochastic_scenario.name => s,)...,t=vintage_t)
                    tech_discount_rate = discnt_rate_tech(;Dict(obj_cls.name => id, stochastic_scenario.name => s,)...,t=vintage_t)
                    discnt_rate = discount_rate(model=instance, stochastic_scenario=s,t=vintage_t) #TODO time and stoch dependent
                    val = capital_recovery_factor(instance,tech_discount_rate,ELIFE)/capital_recovery_factor(instance,discnt_rate,ELIFE)
                end
                push!(stoch_map_val,val)
                push!(stoch_map_ind,s)
            end
            obj_cls.parameter_values[id][param_name] = parameter_value(SpineInterface.Map(stoch_map_ind,stoch_map_val))
        else
            obj_cls.parameter_values[id][param_name] = parameter_value(1)
        end
    end

    @eval begin
        $(param_name) = $(Parameter(param_name, [obj_cls]))
    end
end




"""
    generate_discount_timeslice_duration()

Generate discounted duration of timeslices for each investment timeslice.
This is used to scale and translate operational blocks according to their associated investment period, and
discount them to the models `discount_year`.
"""
function generate_discount_timeslice_duration!(m::Model, obj_cls::ObjectClass, obj_name::Symbol)
    instance = m.ext[:spineopt].instance
    discnt_year = discount_year(model=instance)
    discounted_duration = Dict()
    invest_stoch_struct = eval(Symbol("$(obj_cls)__investment_stochastic_structure"))
    invest_temporal_block = eval(Symbol("$(obj_cls)__investment_temporal_block"))
    param_name = Symbol("$(obj_cls)_discounted_duration")
    if use_milestone_years(model=instance)
        for id in obj_cls()
            if isempty(invest_temporal_block()) || isempty(invest_temporal_block(;Dict(obj_cls.name=>id,)...))
                invest_temporal_block_ = model__default_investment_temporal_block(model=instance)
                @warn "Using milestone year without investments is currently not supported; using default investment temporal block for $id"
            else
                invest_temporal_block_ = invest_temporal_block(;Dict(obj_cls.name=>id,)...)
            end
            if !isempty(invest_stoch_struct(;Dict(obj_cls.name=>id,)...))
                stoch_map_val = []
                stoch_map_ind = []
                for s in invest_stoch_struct(;Dict(obj_cls.name=>id,)...)
                    for (s_all,t) in stochastic_time_indices(m;temporal_block=invest_temporal_block_,stochastic_scenario=_find_children(s))
                        timeseries_ind, timeseries_val = create_discounted_duration(m;stochastic_scenario=s, invest_temporal_block=t.block)
                        push!(stoch_map_ind,s_all)
                        push!(stoch_map_val,TimeSeries(timeseries_ind,timeseries_val,false,false))
                    end
                end
                obj_cls.parameter_values[id][param_name] = parameter_value(SpineInterface.Map(stoch_map_ind,stoch_map_val))
            else
                timeseries_ind, timeseries_val = create_discounted_duration(m; invest_temporal_block=invest_temporal_block_)
                obj_cls.parameter_values[id][param_name] = parameter_value(TimeSeries(timeseries_ind,timeseries_val,false,false))
            end
        end
    else
        for id in obj_cls()
            timeseries_ind = []
            timeseries_val = []
            for model_years in first(time_slice(m)).start.x:Year(1):last(time_slice(m)).end_.x+Year(1)
                ### How to find overlapping stochastic scenarios?
                ### TODO: should this be model start OR current_window?
                discnt_rate = discount_rate(model=instance , t=model_years)
                val = discount_factor(instance,discnt_rate,model_years)
                push!(timeseries_ind,model_years)
                push!(timeseries_val,val)
            end
            obj_cls.parameter_values[id][param_name] = parameter_value(SpineInterface.TimeSeries(timeseries_ind,timeseries_val,false,false))
        end
    end
    @eval begin
        $(param_name) = $(Parameter(param_name, [obj_cls]))
    end
end
"""
"""
function create_discounted_duration(m;stochastic_scenario=nothing,invest_temporal_block=nothing)
    timeseries_ind = []
    timeseries_val = []
    instance = m.ext[:spineopt].instance
    last_timestep = end_(last(time_slice(m; temporal_block = invest_temporal_block)))
    for t in Iterators.flatten((time_slice(m; temporal_block = invest_temporal_block),TimeSlice(last_timestep,last_timestep)))
        discnt_rate = discount_rate(model=instance, stochastic_scenario=stochastic_scenario, t=t)
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
    timeseries_ind,timeseries_val
end

"""
    generate_decommissioning_conversion_to_discounted_annuities()

The decommissioning_conversion_to_discounted_annuities factor translates the overnight costs of an investment
into discounted (to the `dicount_year`) annual payments, distributed over the decommissioning time of the investment.
Investment payments are assumed to be constant over the decommissioning time.

"""
function generate_decommissioning_conversion_to_discounted_annuities!(m::Model, obj_cls::ObjectClass, obj_name::Symbol)
    instance = m.ext[:spineopt].instance
    discnt_year = discount_year(model=instance)
    decommissioning_conversion_to_discounted_annuities = Dict()
    investment_indices = eval(Symbol("$(obj_name)s_invested_available_indices"))
    decom_time = eval(Symbol("$(obj_name)_decommissioning_time"))
    decom_cost = eval(Symbol("$(obj_name)_decommissioning_cost"))
    param_name = Symbol("$(obj_name)_decommissioning_conversion_to_discounted_annuities")
    for id in indices(decom_cost)
        stochastic_map_indices = []
        stochastic_map_vals = []
        for s in unique([x.stochastic_scenario for x in investment_indices(m)]) #NOTE: this is specific to lifetimes in years
            timeseries_ind = []
            timeseries_val = []
            for (u,s,vintage_t) in investment_indices(m;Dict(obj_cls.name=>id,:stochastic_scenario=>s)...)
                DECOM_T = decom_time(;Dict(obj_cls.name=>id,:stochastic_scenario=>s,:t=>vintage_t)...)
                if isnothing(DECOM_T)
                    DECOM_T = Year(0)
                    #NOTE: if decom time not defined, assumed to be 0 years.
                end
                vintage_t_start = start(vintage_t)
                end_of_decommissioning = vintage_t_start + DECOM_T
                j = vintage_t_start
                val = 0
                discnt_rate = discount_rate(model=instance, stochastic_scenario=s) #TODO time and stoch dependent
                while j<= end_of_decommissioning
                    val+= discount_factor(instance,discnt_rate,j) #payment_fraction would always be 1
                    j+= Year(1)
                end
                push!(timeseries_ind,start(vintage_t))
                push!(timeseries_val,val*capital_recovery_factor(instance, discnt_rate,DECOM_T))
            end
            push!(stochastic_map_indices,s)
            push!(stochastic_map_vals,TimeSeries(timeseries_ind,timeseries_val,false,false))
        end
        obj_cls.parameter_values[id][param_name] = parameter_value(SpineInterface.Map(stochastic_map_indices,stochastic_map_vals))
    end
    @eval begin
        $(param_name) = $(Parameter(param_name, [obj_cls]))
    end
end

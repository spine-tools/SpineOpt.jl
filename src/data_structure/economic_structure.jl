#############################################################################
# Copyright (C) 2017 - 2021 Spine project consortium
# Copyright SpineOpt contributors
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
    generate_economic_structure!(m)
"""
function generate_economic_structure!(m; log_level=3)
    !isnothing(multiyear_economic_discounting(model=m.ext[:spineopt].instance)) || return
    if !isnothing(roll_forward(model=m.ext[:spineopt].instance))
        error("Using multiyear economic discounting with rolling horizon is currently not supported.")
    elseif model_type(model=m.ext[:spineopt].instance) === :spineopt_benders 
        error("Using multiyear economic discounting with Benders' decomposition is currently not supported.")
    end
    if isempty(model__default_investment_temporal_block()) &&
       isempty(node__investment_temporal_block()) &&
       isempty(unit__investment_temporal_block()) &&
       isempty(connection__investment_temporal_block())
        error("Using multiyear economic discounting without defining investment temporal blocks is currently not supported.")
    end
    economic_parameters = _create_set_parameters_and_relationships()
    for (obj, name) in [(unit, :unit), (node, :storage), (connection, :connection)]
        @timelog log_level 3 "- [Generated discounted durations for $(obj)s]" begin
            generate_discount_timeslice_duration!(m, obj, economic_parameters)
        end
        @timelog log_level 3 "- [Generated capacity transfer factors for $(name)s]" begin
            generate_capacity_transfer_factor!(m, obj, economic_parameters)
        end
        @timelog log_level 3 "- [Generated conversion to discounted investments of $(name)s]" begin
            generate_conversion_to_discounted_annuities!(m, obj, economic_parameters)
        end
        @timelog log_level 3 "- [Generated conversion for discounted decommissioning of $(name)s]" begin
            generate_decommissioning_conversion_to_discounted_annuities!(m, obj, economic_parameters)
        end
        @timelog log_level 3 "- [Generated salvage fraction for $(name)s]" begin 
            generate_salvage_fraction!(m, obj, economic_parameters)
        end
        @timelog log_level 3 "- [Generated $(name) technology specific discount factors]" begin 
            generate_tech_discount_factor!(m, obj, economic_parameters)
        end
    end
end

function _create_set_parameters_and_relationships()
    economic_parameters = Dict(
        unit => Dict(
            :set_investment_indices => units_invested_available_indices,
            :set_invest_temporal_block => unit__investment_temporal_block,
            :set_invest_stoch_struct => unit__investment_stochastic_structure,
            :set_lead_time => unit_lead_time,
            :set_tech_lifetime => unit_investment_tech_lifetime,
            :set_econ_lifetime => unit_investment_econ_lifetime,
            :set_discnt_rate_tech => unit_discount_rate_technology_specific,
            :set_decom_time => unit_decommissioning_time,
            :set_decom_cost => unit_decommissioning_cost,
            :set_capacity_transfer_factor => :unit_capacity_transfer_factor,
            :set_conversion_to_discounted_annuities => :unit_conversion_to_discounted_annuities,
            :set_salvage_fraction => :unit_salvage_fraction,
            :set_tech_discount_factor => :unit_tech_discount_factor,
            :set_discounted_duration => :unit_discounted_duration,
            :set_decommissioning_conversion_to_discounted_annuities => :unit_decommissioning_conversion_to_discounted_annuities,
        ),
        node => Dict(
            :set_investment_indices => storages_invested_available_indices,
            :set_invest_temporal_block => node__investment_temporal_block,
            :set_invest_stoch_struct => node__investment_stochastic_structure,
            :set_lead_time => storage_lead_time,
            :set_tech_lifetime => storage_investment_tech_lifetime,
            :set_econ_lifetime => storage_investment_econ_lifetime,
            :set_discnt_rate_tech => storage_discount_rate_technology_specific,
            :set_decom_time => storage_decommissioning_time,
            :set_decom_cost => storage_decommissioning_cost,
            :set_capacity_transfer_factor => :storage_capacity_transfer_factor,
            :set_conversion_to_discounted_annuities => :storage_conversion_to_discounted_annuities,
            :set_salvage_fraction => :storage_salvage_fraction,
            :set_tech_discount_factor => :storage_tech_discount_factor,
            :set_discounted_duration => :storage_discounted_duration,
            :set_decommissioning_conversion_to_discounted_annuities => :storage_decommissioning_conversion_to_discounted_annuities,
        ),
        connection => Dict(
            :set_investment_indices => connections_invested_available_indices,
            :set_invest_temporal_block => connection__investment_temporal_block,
            :set_invest_stoch_struct => connection__investment_stochastic_structure,
            :set_lead_time => connection_lead_time,
            :set_tech_lifetime => connection_investment_tech_lifetime,
            :set_econ_lifetime => connection_investment_econ_lifetime,
            :set_discnt_rate_tech => connection_discount_rate_technology_specific,
            :set_decom_time => connection_decommissioning_time,
            :set_decom_cost => connection_decommissioning_cost,
            :set_capacity_transfer_factor => :connection_capacity_transfer_factor,
            :set_conversion_to_discounted_annuities => :connection_conversion_to_discounted_annuities,
            :set_salvage_fraction => :connection_salvage_fraction,
            :set_tech_discount_factor => :connection_tech_discount_factor,
            :set_discounted_duration => :connection_discounted_duration,
            :set_decommissioning_conversion_to_discounted_annuities => :connection_decommissioning_conversion_to_discounted_annuities,
        )
    )
end

"""
    generate_unit_capacity_transfer_factor()

Generate capacity_transfer_factor factors for units that can be invested in. The
unit_capacity_transfer_factor is a Map parameter that holds the fraction of an investment during vintage
year t_v in a unit u that is still available in the model year t.
"""
function generate_capacity_transfer_factor!(m::Model, obj_cls::ObjectClass, economic_parameters::Dict)
    instance = m.ext[:spineopt].instance
    capacity_transfer_factor = Dict()
    investment_indices = economic_parameters[obj_cls][:set_investment_indices]
    lead_time = economic_parameters[obj_cls][:set_lead_time]
    tech_lifetime = economic_parameters[obj_cls][:set_tech_lifetime]
    invest_temporal_block = economic_parameters[obj_cls][:set_invest_temporal_block]
    param_name = economic_parameters[obj_cls][:set_capacity_transfer_factor]

    # Default value of 1 for all (investable + non-investable)
    for id in obj_cls()
        pvals = parameter_value(1)
        add_object_parameter_values!(obj_cls, Dict(id => Dict(param_name => pvals)))
    end

    for id in invest_temporal_block(temporal_block=anything)
        if (
            !isnothing(tech_lifetime(; Dict(obj_cls.name => id)...)) ||
            !(isnothing(lead_time(; Dict(obj_cls.name => id)...)) || iszero(lead_time(; Dict(obj_cls.name => id)...)))
        )
            stoch_scenarios_vector =
                unique([x.stochastic_scenario for x in investment_indices(m; Dict(obj_cls.name => id)...)])
            map_stoch_indices = [] #NOTE: will hold stochastic indices
            sizehint!(map_stoch_indices, length(stoch_scenarios_vector))
            map_inner = [] #NOTE: will map values inside stochastic mapping
            sizehint!(map_inner, length(stoch_scenarios_vector))
            for s in stoch_scenarios_vector
                investment_indices_vector = investment_indices(
                    m;
                    Dict(
                        obj_cls.name => id,
                        :stochastic_scenario => s,
                        :t => Iterators.flatten((SpineOpt.history_time_slice(m), time_slice(m))),
                    )...,
                )
                map_indices = []
                count = length(collect(investment_indices_vector)) 
                sizehint!(map_indices, count)
                timeseries_array = []
                sizehint!(timeseries_array, count)
                for (u, s, vintage_t) in investment_indices_vector
                    # get lead time
                    p_lt = lead_time(; Dict(obj_cls.name => id, :stochastic_scenario => s, :t => vintage_t)...)
                    if isnothing(p_lt)
                        p_lt = Year(0)
                        #NOTE: In case p_lt is `none`, we will assume a duration of `0 Years`
                    end
                    # get tech lifetime
                    p_tlife = tech_lifetime(; Dict(obj_cls.name => id, :stochastic_scenario => s, :t => vintage_t)...)
                    if isnothing(p_tlife)
                        max(Year(last(time_slice(m)).start.x) - Year(first(time_slice(m)).end_.x), Year(1))
                        #NOTE: In case p_tlife is `none`, we assume that the unit exists until the end of the optimization
                    end
                    vintage_t_start = start(vintage_t)
                    start_of_operation = vintage_t_start + p_lt
                    end_of_operation = vintage_t_start + p_lt + p_tlife
                    time_slice_vector = time_slice(
                        m;
                        temporal_block=invest_temporal_block(; Dict(obj_cls.name => id)...),
                        t=Iterators.flatten((SpineOpt.history_time_slice(m), time_slice(m))),
                    )
                    timeseries_val = []
                    sizehint!(timeseries_val, length(time_slice_vector))
                    timeseries_ind = []
                    sizehint!(timeseries_ind, length(time_slice_vector))
                    for t in time_slice_vector
                        t_start = start(t)
                        t_end = end_(t)
                        dur = t_end - t_start
                        if t_end < start_of_operation
                            val = 0
                            #=NOTE:
                            if the end of the timeslice t is before the start of operation for a unit installed
                            at vntage year vintage_t_start => no capacity available yet at t_end=#
                        elseif t_start < start_of_operation
                            val = max(min(1 - (start_of_operation - t_start) / dur, 1), 0)
                            #=NOTE:
                            if the end of timeslice t is after the start of operation and the start of the timeslice t
                            is before the start of operation, val will take a value between 0 and 1, depending on
                            how much of this capacity is available on average during t=#
                        else
                            val = max(min((end_of_operation - t_start) / dur, 1), 0)
                            #=NOTE:
                            in all other cases, val will describe the fraction [0,1] that is (still) available at
                            time step t. This will be 1, if the technology does not get decomissioned during t,
                            a fraction, if the technology gets decomssioned during t, and 0 for all other cases (fully decomissioned)
                            =#
                        end
                        capacity_transfer_factor[(id, vintage_t.start.x, t.start.x)] = parameter_value(val)
                        push!(timeseries_val, val)
                        push!(timeseries_ind, t_start)
                    end
                    push!(map_indices, vintage_t_start)
                    push!(timeseries_array, TimeSeries(timeseries_ind, timeseries_val, false, false))
                end
                push!(map_stoch_indices, s)
                push!(map_inner, SpineInterface.Map(map_indices, timeseries_array))
            end
            pvals = parameter_value(SpineInterface.Map(map_stoch_indices, map_inner))
            #NOTE: map_indices here will be stochastic_scenarios!
        else
            pvals = parameter_value(1)
        end
        add_object_parameter_values!(obj_cls, Dict(id => Dict(param_name => pvals)))
    end
    @eval begin
        $(param_name) = $(Parameter(param_name, [obj_cls]; mod = @__MODULE__))
    end
end

"""
    generate_conversion_to_discounted_annuities()

The conversion_to_discounted_annuities factor translates the overnight costs of an investment
into discounted (to the `discount_year`) annual payments, distributed over the total
lifetime of the investment. Investment payments are assumed to increase linearly over the lead-time, and decrease
linearly towards the end of the economic lifetime.
"""
function generate_conversion_to_discounted_annuities!(m::Model, obj_cls::ObjectClass, economic_parameters::Dict)
    instance = m.ext[:spineopt].instance
    discnt_year = discount_year(model=instance)
    conversion_to_discounted_annuities = Dict()
    investment_indices = economic_parameters[obj_cls][:set_investment_indices]
    invest_temporal_block = economic_parameters[obj_cls][:set_invest_temporal_block]
    lead_time = economic_parameters[obj_cls][:set_lead_time]
    econ_lifetime = economic_parameters[obj_cls][:set_econ_lifetime]
    param_name = economic_parameters[obj_cls][:set_conversion_to_discounted_annuities] # this is MARKUP^AN

    for id in obj_cls()
        # if the discount rate is 0 or not defined, the conversion factor is 1
        # or if the object is not investable, the conversion factor is also 1
        if (discount_rate(model=model()[1]) == 0 || isnothing(discount_rate(model=model()[1])) || !(id in invest_temporal_block(temporal_block=anything)))
            pvals = parameter_value(1)
        else
            stochastic_map_vector = unique([x.stochastic_scenario for x in investment_indices(m)])
            stochastic_map_indices = []
            sizehint!(stochastic_map_indices, length(stochastic_map_vector))
            stochastic_map_vals = []
            sizehint!(stochastic_map_vals, length(stochastic_map_vector))
            for s in stochastic_map_vector
                time_series_vector = investment_indices(m; Dict(obj_cls.name => id, :stochastic_scenario => s)...)
                timeseries_ind = []
                count = length(collect(time_series_vector))
                sizehint!(timeseries_ind, count)
                timeseries_val = []
                sizehint!(timeseries_val, count)
                for (u, s, vintage_t) in time_series_vector
                    discnt_rate = discount_rate(model=instance, stochastic_scenario=s, t=vintage_t)
                    p_lt = lead_time(; Dict(obj_cls.name => id, :stochastic_scenario => s, :t => vintage_t)...)
                    if isnothing(p_lt)
                        p_lt = Year(0)
                    end
                    p_elife = econ_lifetime(; Dict(obj_cls.name => id, :stochastic_scenario => s, :t => vintage_t)...)
                    vintage_t_start = start(vintage_t)
                    if isnothing(econ_lifetime(; Dict(obj_cls.name => id)...))
                        ### if empty it should translate to discounted overnight costs
                        val = discount_factor(instance, discnt_rate, vintage_t_start)
                        push!(timeseries_ind, vintage_t_start)
                        push!(timeseries_val, val)
                    else
                        end_of_operation = vintage_t_start + p_lt + p_elife
                        j = vintage_t_start
                        val = 0
                        while j <= end_of_operation
                            val +=
                                payment_fraction(vintage_t_start, j, p_elife, p_lt) *
                                discount_factor(instance, discnt_rate, j) #1/(1+discnt_rate)^((Year(j)-Year(discnt_year))/Year(1))
                            j += Year(1)
                        end
                        push!(timeseries_ind, start(vintage_t))
                        push!(timeseries_val, val * capital_recovery_factor(instance, discnt_rate, p_elife))
                    end
                end
                push!(stochastic_map_indices, s)
                push!(stochastic_map_vals, TimeSeries(timeseries_ind, timeseries_val, false, false))
            end
            pvals = parameter_value(SpineInterface.Map(stochastic_map_indices, stochastic_map_vals))
        end
        add_object_parameter_values!(obj_cls, Dict(id => Dict(param_name => pvals)))
    end
    @eval begin
        $(param_name) = $(Parameter(param_name, [obj_cls]; mod = @__MODULE__))
    end
end

"""
    function capital_recovery_factor(m, discnt_rate ,p_elife)

The `captial_recovery_factor` is the ratio between constant annuities and the present value of these annuities over the economic lifetime of the investment.
"""

function capital_recovery_factor(m, discnt_rate, p_elife)
    if p_elife.value == 0
        p_elife = Year(0)
    end
    if discnt_rate != 0
        capital_recovery_factor =
            discnt_rate / (1 + discnt_rate) * 1 / (discount_factor(m, discnt_rate, p_elife)) * 1 /
            (1 / (discount_factor(m, discnt_rate, p_elife)) - 1)
    else
        capital_recovery_factor = 1 / (Year(p_elife) / Year(1))
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
    discnt_factor = 1 / (1 + discnt_rate)^((Year(year) - Year(discnt_year)) / Year(1))
end

function discount_factor(m, discnt_rate, year::Union{T,Nothing}) where {T<:Period}
    if year.value == 0
        year = Year(0)
    end
    discnt_factor = 1 / (1 + discnt_rate)^((Year(year)) / Year(1))
end

"""
function payment_fraction(t_vintage, t, t_econ_life, t_lead)

`payment_fraction` for technology u with vintage year t_vintage that needs to be paid
in payment year t. Depends on leadtime and economic lifetime of u (assumed to increase linearly over leadtime, and decrease linearly towards the end of the economic lifetime).
"""
function payment_fraction(t_vintage, t, t_econ_life, t_lead)
    t_lead = t_lead.value == 0 ? Year(1) : t_lead
    p_up = min(t_vintage + t_lead - Year(1), t)
    p_down = max(t_vintage, t - t_econ_life + Year(1))
    pfrac = max((Year(p_up) - Year(p_down) + Year(1)) / t_lead, 0)
end

"""
    generate_salvage_fraction()

Generate salvage fraction of units, whose economic lifetime exceeds the modeling horizon.
"""
function generate_salvage_fraction!(m::Model, obj_cls::ObjectClass, economic_parameters::Dict)
    instance = m.ext[:spineopt].instance
    discnt_year = discount_year(model=instance)
    p_eoh = model_end(model=instance)
    salvage_fraction = Dict()
    investment_indices = economic_parameters[obj_cls][:set_investment_indices]
    lead_time = economic_parameters[obj_cls][:set_lead_time]
    econ_lifetime = economic_parameters[obj_cls][:set_econ_lifetime]
    invest_temporal_block = economic_parameters[obj_cls][:set_invest_temporal_block]
    param_name = economic_parameters[obj_cls][:set_salvage_fraction]
     
    # Default value of 0 for all (investable + non-investable)
    for id in obj_cls()
        pvals = parameter_value(0)
        add_object_parameter_values!(obj_cls, Dict(id => Dict(param_name => pvals)))
    end

    # Only for investable objects
    for id in invest_temporal_block(temporal_block=anything)
        if id in indices(econ_lifetime)
            stochastic_map_vector = unique([x.stochastic_scenario for x in investment_indices(m)])
            stochastic_map_ind = []
            sizehint!(stochastic_map_ind, length(stochastic_map_vector))
            stochastic_map_val = []
            sizehint!(stochastic_map_val, length(stochastic_map_vector))
            for s in stochastic_map_vector
                timeseries_vector = time_slice(m; temporal_block=invest_temporal_block(; Dict(obj_cls.name => id)...))
                timeseries_ind = []
                sizehint!(timeseries_ind, length(timeseries_vector))
                timeseries_val = []
                sizehint!(timeseries_val, length(timeseries_vector))
                for vintage_t in timeseries_vector
                    p_elife = econ_lifetime(; Dict(obj_cls.name => id, stochastic_scenario.name => s)..., t=vintage_t)
                    p_lt = lead_time(; Dict(obj_cls.name => id, stochastic_scenario.name => s)..., t=vintage_t)
                    if isnothing(p_lt)
                        p_lt = Year(0)
                    end
                    discnt_rate = discount_rate(model=instance, stochastic_scenario=s, t=vintage_t)
                    vintage_t_start = start(vintage_t)
                    start_of_operation = vintage_t_start + p_lt
                    end_of_operation = vintage_t_start + p_lt + p_elife
                    j1 = p_eoh + Year(1)
                    j2 = vintage_t_start
                    val1 = 0
                    val2 = 0
                    while j1 <= end_of_operation
                        val1 +=
                            payment_fraction(vintage_t_start, j1, p_elife, p_lt) *
                            discount_factor(instance, discnt_rate, j1)
                        j1 += Year(1)
                    end
                    while j2 <= end_of_operation
                        val2 +=
                            payment_fraction(vintage_t_start, j2, p_elife, p_lt) *
                            discount_factor(instance, discnt_rate, j2)
                        j2 += Year(1)
                    end
                    val2 == 0 ? val = 0 : val = max(val1 / val2, 0)
                    push!(timeseries_ind, start(vintage_t))
                    push!(timeseries_val, val)
                end
                push!(stochastic_map_ind, s)
                push!(stochastic_map_val, TimeSeries(timeseries_ind, timeseries_val, false, false))
            end
            pvals = parameter_value(SpineInterface.Map(stochastic_map_ind, stochastic_map_val))
        else
            pvals = parameter_value(0)
        end
        add_object_parameter_values!(obj_cls, Dict(id => Dict(param_name => pvals)))
    end
    @eval begin
        $(param_name) = $(Parameter(param_name, [obj_cls]; mod = @__MODULE__))
    end
end

"""
    generate_tech_discount_factor()

Generate technology-specific discount factors for investments (e.g., for risky investments).
"""
function generate_tech_discount_factor!(m::Model, obj_cls::ObjectClass, economic_parameters::Dict)
    instance = m.ext[:spineopt].instance
    investment_indices = economic_parameters[obj_cls][:set_investment_indices]
    econ_lifetime = economic_parameters[obj_cls][:set_econ_lifetime]
    discnt_rate_tech = economic_parameters[obj_cls][:set_discnt_rate_tech]
    invest_stoch_struct = economic_parameters[obj_cls][:set_invest_stoch_struct]
    param_name = economic_parameters[obj_cls][:set_tech_discount_factor]

    for id in obj_cls()
        if (
            !isnothing(discnt_rate_tech(; Dict(obj_cls.name => id)...)) &&
            discnt_rate_tech(; Dict(obj_cls.name => id)...) != 0 &&
            !isnothing(econ_lifetime(; Dict(obj_cls.name => id)...))
        )
            stochastic_struct = if isempty(invest_stoch_struct(; Dict(obj_cls.name => id)...))
                model__default_stochastic_structure(model=instance)
            else
                invest_stoch_struct(; Dict(obj_cls.name => id)...)
            end
            stoch_map_vector = stochastic_structure__stochastic_scenario(
                stochastic_structure=stochastic_struct,
            )
            stoch_map_val = []
            sizehint!(stoch_map_val, length(stoch_map_vector))
            stoch_map_ind = []
            sizehint!(stoch_map_ind, length(stoch_map_vector))
            for s in stoch_map_vector
                val = 0
                for (u, s, vintage_t) in investment_indices(m; Dict(obj_cls.name => id, :stochastic_scenario => s)...)
                    p_elife = econ_lifetime(; Dict(obj_cls.name => id, stochastic_scenario.name => s)..., t=vintage_t)
                    tech_discount_rate =
                        discnt_rate_tech(; Dict(obj_cls.name => id, stochastic_scenario.name => s)..., t=vintage_t)
                    discnt_rate = discount_rate(model=instance, stochastic_scenario=s, t=vintage_t)
                    val =
                        capital_recovery_factor(instance, tech_discount_rate, p_elife) /
                        capital_recovery_factor(instance, discnt_rate, p_elife)
                end
                push!(stoch_map_val, val)
                push!(stoch_map_ind, s)
            end
            pvals = parameter_value(SpineInterface.Map(stoch_map_ind, stoch_map_val))
        else
            pvals = parameter_value(1)
        end
        add_object_parameter_values!(obj_cls, Dict(id => Dict(param_name => pvals)))
    end
    @eval begin
        $(param_name) = $(Parameter(param_name, [obj_cls]; mod = @__MODULE__))
    end
end

"""
    generate_discount_timeslice_duration()

Generate discounted duration of timeslices for each investment timeslice.
This is used to scale and translate operational blocks according to their associated investment period, and
discount them to the models `discount_year`.
"""
function generate_discount_timeslice_duration!(m::Model, obj_cls::ObjectClass, economic_parameters::Dict)
    instance = m.ext[:spineopt].instance
    discnt_year = discount_year(model=instance)
    discounted_duration = Dict()
    invest_stoch_struct = economic_parameters[obj_cls][:set_invest_stoch_struct]
    invest_temporal_block = economic_parameters[obj_cls][:set_invest_temporal_block]
    param_name = economic_parameters[obj_cls][:set_discounted_duration]

    if multiyear_economic_discounting(model=instance) == :milestone_years
        for id in obj_cls()
            if isempty(invest_temporal_block()) || isempty(invest_temporal_block(; Dict(obj_cls.name => id)...))
                invest_temporal_block_ = model__default_investment_temporal_block(model=instance)
                @info "No specific investment temporal block is defined for $obj_cls '$id', use the default investment temporal block."
            else
                invest_temporal_block_ = invest_temporal_block(; Dict(obj_cls.name => id)...) # set specific investment temporal block
            end
            stoch_map_vector = invest_stoch_struct(; Dict(obj_cls.name => id)...)
            if !isempty(stoch_map_vector)
                stoch_map_val = []
                sizehint!(stoch_map_val, length(stoch_map_vector))
                stoch_map_ind = []
                sizehint!(stoch_map_ind, length(stoch_map_vector))
                for s in stoch_map_vector
                    for (s_all, t) in stochastic_time_indices(
                        m;
                        temporal_block=invest_temporal_block_,
                        stochastic_scenario=_find_children(s),
                    )
                        timeseries_ind, timeseries_val =
                            create_discounted_duration(m; stochastic_scenario=s, invest_temporal_block=t.block)
                        push!(stoch_map_ind, s_all)
                        push!(stoch_map_val, TimeSeries(timeseries_ind, timeseries_val, false, false))
                    end
                end
                pvals = parameter_value(SpineInterface.Map(stoch_map_ind, stoch_map_val))
            else
                timeseries_ind, timeseries_val =
                    create_discounted_duration(m; invest_temporal_block=invest_temporal_block_)
                pvals = parameter_value(TimeSeries(timeseries_ind, timeseries_val, false, false))
            end
            add_object_parameter_values!(obj_cls, Dict(id => Dict(param_name => pvals)))
        end
    elseif  multiyear_economic_discounting(model=instance) == :consecutive_years 
    # if using consecutive years, we only need a discount rate for each year 
        for id in obj_cls()
            timeseries_ind = []
            timeseries_val = []
            for model_years in (first(time_slice(m)).start.x):Year(1):(last(time_slice(m)).end_.x + Year(1))
                discnt_rate = discount_rate(model=instance, t=model_years)
                val = discount_factor(instance, discnt_rate, model_years)
                push!(timeseries_ind, model_years)
                push!(timeseries_val, val)
            end
            pvals = parameter_value(SpineInterface.TimeSeries(timeseries_ind, timeseries_val, false, false))
            add_object_parameter_values!(obj_cls, Dict(id => Dict(param_name => pvals)))
        end
    end
    @eval begin
        $(param_name) = $(Parameter(param_name, [obj_cls]; mod = @__MODULE__))
    end
end
"""
    Create_discounted_duration()

Create discounted duration of timeslices for each investment timeslice.
"""
function create_discounted_duration(m; stochastic_scenario=nothing, invest_temporal_block=nothing)
    instance = m.ext[:spineopt].instance
    last_timestep = end_(last(time_slice(m; temporal_block=invest_temporal_block)))
    timeseries_vector = Iterators.flatten((
        time_slice(m; temporal_block=invest_temporal_block),
        TimeSlice(last_timestep, last_timestep),
    ))
    count = length(collect(timeseries_vector)) # count the element; this is to avoid using collect
    timeseries_ind = []
    sizehint!(timeseries_ind, count)
    timeseries_val = []
    sizehint!(timeseries_val, count)
    for t in timeseries_vector
        discnt_rate = discount_rate(model=instance, stochastic_scenario=stochastic_scenario, t=t)
        t_start = start(t)
        t_end = end_(t)
        j = t_start
        val = 0
        while j < t_end
            val += discount_factor(instance, discnt_rate, j)
            j += Year(1)
        end
        push!(timeseries_ind, start(t))
        push!(timeseries_val, val)
    end
    timeseries_ind, timeseries_val
end

function discounted_duration_base(t::TimeSlice; _exact=false)
    # The economic discounting uses 1 Year as the base duration for investment (years) and operation.
    # This means that an `xx_discounted_duration` only counts the number (discounted) of years in an investment period,
    # assuming (1) the "investment period" = n years with n>=1 being an integer, 
    # and (2) the "operational period" = 1 Year.
    # Hence, the product `xx_discounted_duration` and `duration(t)` is only valid when t spans no more than 1 year.
    # When `duration(t)` > 1 Year, the product would double-counts the years in a multi-year investment period setup.
    # In this case, we need this substituting coefficient for `duration(t)` to represent the length (in hour) of 1 Year.

    # We assume the 1st year of the investment period as the base.
    _base_duration = TimeSlice(start(t), start(t)+Year(1)) |> duration
    # average number of years during one investment window period, rounded to integer.
    _number_of_years = div(duration(t), _base_duration, RoundNearest)
    
    # This conditional is irrelevant to whether the asset is investable or not.
    if _number_of_years <= 1
        return duration(t)
    else
        # _exact=true calculates the average length of 1 Year of a multi-year investment period.
        # _exact=false assumes the investment period consists of multiple of the base (1 Year).
        return _exact ? duration(t)/_number_of_years : _base_duration
    end
end

"""
    generate_decommissioning_conversion_to_discounted_annuities()

The decommissioning_conversion_to_discounted_annuities factor translates the overnight costs of an investment
into discounted (to the `dicount_year`) annual payments, distributed over the decommissioning time of the investment.
Investment payments are assumed to be constant over the decommissioning time.
"""
function generate_decommissioning_conversion_to_discounted_annuities!(
    m::Model,
    obj_cls::ObjectClass,
    economic_parameters::Dict,
)
    instance = m.ext[:spineopt].instance
    discnt_year = discount_year(model=instance)
    decommissioning_conversion_to_discounted_annuities = Dict()
    investment_indices = economic_parameters[obj_cls][:set_investment_indices]
    decom_time = economic_parameters[obj_cls][:set_decom_time]
    decom_cost = economic_parameters[obj_cls][:set_decom_cost]
    param_name = economic_parameters[obj_cls][:set_decommissioning_conversion_to_discounted_annuities]

    # Default value of 1 for all (decommissionable + non-decommissionable)
    for id in obj_cls()
        pvals = parameter_value(1)
        add_object_parameter_values!(obj_cls, Dict(id => Dict(param_name => pvals)))
    end

    for id in indices(decom_cost)
        stochastic_map_vector = unique([x.stochastic_scenario for x in investment_indices(m)])
        stochastic_map_indices = []
        sizehint!(stochastic_map_indices, length(stochastic_map_vector))
        stochastic_map_vals = []
        sizehint!(stochastic_map_vals, length(stochastic_map_vector))
        for s in stochastic_map_vector
            timeseries_vector = investment_indices(m; Dict(obj_cls.name => id, :stochastic_scenario => s)...)
            timeseries_ind = []
            count = 0 # count the element; this is to avoid using collect
            for _ in timeseries_vector
                count += 1
            end
            sizehint!(timeseries_ind, count)
            timeseries_val = []
            sizehint!(timeseries_val, count)
            for (u, s, vintage_t) in timeseries_vector
                p_decom_t = decom_time(; Dict(obj_cls.name => id, :stochastic_scenario => s, :t => vintage_t)...)
                if isnothing(p_decom_t)
                    p_decom_t = Year(0)
                end
                vintage_t_start = start(vintage_t)
                end_of_decommissioning = vintage_t_start + p_decom_t
                j = vintage_t_start
                val = 0
                discnt_rate = discount_rate(model=instance, stochastic_scenario=s)
                while j <= end_of_decommissioning
                    val += discount_factor(instance, discnt_rate, j)
                    j += Year(1)
                end
                push!(timeseries_ind, start(vintage_t))
                push!(timeseries_val, val * capital_recovery_factor(instance, discnt_rate, p_decom_t))
            end
            push!(stochastic_map_indices, s)
            push!(stochastic_map_vals, TimeSeries(timeseries_ind, timeseries_val, false, false))
        end
        pvals = parameter_value(SpineInterface.Map(stochastic_map_indices, stochastic_map_vals))
        add_object_parameter_values!(obj_cls, Dict(id => Dict(param_name => pvals)))
    end
    @eval begin
        $(param_name) = $(Parameter(param_name, [obj_cls]; mod = @__MODULE__))
    end
end

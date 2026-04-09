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

const _monte_carlo_scenario = Dict()	
const _proc_count = Ref(1)
const _proc_id = Ref(1)

function set_proc_count(x)
	_proc_count[] = x
end

function set_proc_id(x)
	_proc_id[] = x
end

"""
Run SpineOpt with Monte Carlo algorithm.

Parameter `monte_carlo_scenarios` must be a map from scenario key, to array of scenario values. E.g.:

| scenario_key | scenario_values |
| wheather_year | [1997, 2003, 2012] |
| forced_outage_pattern | [1, 2, 3] |

Any parameter value that should change with the Monte Carlo iteration must be a Map
from Monte Carlo scenario(s) to value. E.g.:

| weather_year | forced_outage_pattern | value |
| --- | --- | --- |
| 1997 | 2 | TimeSeries |
"""
function do_run_spineopt!(
    m,
    url_out,
    ::Val{:monte_carlo_algorithm};
    log_level,
    optimize,
    update_names,
    alternative,
    write_as_roll,
    resume_file_path,
)
	mc_scens = monte_carlo_scenarios(model=m.ext[:spineopt].instance, _strict=false)
	_check_monte_carlo_scenarios(mc_scens)
	scen_keys_by_model = Dict(m => _monte_carlo_scenario_keys(mc_scens))
	for (st, stage_m) in m.ext[:spineopt].model_by_stage
        with_env(stage_scenario(stage=st)) do
			scen_keys_by_model[stage_m] = _monte_carlo_scenario_keys(mc_scens)
        end
	end
	for (m, scen_keys) in scen_keys_by_model
		_setup_solve_skip!(m, scen_keys)
	end
	models_by_scen_key = Dict()
	for (m, scen_keys) in scen_keys_by_model
		for scen_key in scen_keys
			push!(get!(models_by_scen_key, scen_key, []), m)
		end
	end
	# Sort mc_scens so child keys come before their parent.
	# This is because Iterators.product changes more often the keys at the beginning
	# and we want parent keys to change less often
	# (so parent models don't need to be solved again for the same keys).
	mc_scens = OrderedDict(mc_scens)
	_mc_scen_lt = _make_mc_scen_lt(models_by_scen_key)
	sort!(mc_scens; lt=_mc_scen_lt)
	scenario_keys = keys(mc_scens)
	model_built = false
	for (k, scenario_value_tuple) in enumerate(Iterators.product(values(mc_scens)...))
		if k % _proc_count[] != _proc_id[] - 1
			continue
		end
		scen_id = (; zip(scenario_keys, scenario_value_tuple)...)
		_set_monte_carlo_scenario(scen_id)
		if !model_built
			build_model!(m; log_level)
			model_built = true
		end
		optimize || return m
		solve_model!(
			m; log_level, update_names, output_suffix=scen_id, log_prefix="Monte Carlo scenario $k $scen_id - ",
        ) || @warn "Monte Carlo scenario $scen_id failed to solve, moving on..."
    	write_report(m, url_out; alternative, log_level)
        _clear_results!(m)
	end
end

function _make_mc_scen_lt(models_by_scen_key)
	# Child keys should come before their parent.
	# Key 'x' is a child of key 'y', if 'x' affects a model that is child of a model affected by 'y'.
	# For example, x is outage pattern, it affects only the model;
	# y is weather year, it affects the model and the stage;
	# then x is a child of y and should come before it.
	function _mc_scen_lt(x, y)
		models_x = get(models_by_scen_key, x, ())
		models_y = get(models_by_scen_key, y, ())
		for m_y in setdiff(models_y, models_x)
			st_y = m_y.ext[:spineopt].stage
			st_y === nothing && continue
			for m_x in models_x
				st_x = m_x.ext[:spineopt].stage
				if st_x === nothing || st_x in stage__child_stage(stage=st_y)
					return true
				end
			end
		end
		false
	end
end

_check_monte_carlo_scenarios(_mc_scens) = error(
	"`monte_carlo_scenarios` must be a map from scenario key, to array of scenario values"
)
_check_monte_carlo_scenarios(mc_scens::Map{Symbol,V}) where {V<:Vector} = nothing

"""
	_setup_solve_skip!(m, mc_scen_keys)

Add event handlers to given model so that unneeded solves are skipped,
i.e., whenever the model remains the same after switching to the next Monte Carlo iteration
(because it doesn't have any parameter values that depend on the scenario that changed).
This relies on iterations being sorted nicely so as many solves as possible can be skipped.
"""
function _setup_solve_skip!(m, mc_scen_keys)
    add_event_handler!(m, :model_about_to_solve) do m
    	last_solve_key = (; (k => _monte_carlo_scenario[k][] for k in mc_scen_keys)...)
    	if get(m.ext[:spineopt].extras, :last_solve_key, nothing) == last_solve_key
    		@info "$(_model_name(m)) hasn't changed from last solve - skipping solve..."
    		m.ext[:spineopt].has_results[] = true
    	else
    		m.ext[:spineopt].has_results[] = false
    	end
    end
    add_event_handler!(m, :model_solved) do m
    	last_solve_key = (; (k => _monte_carlo_scenario[k][] for k in mc_scen_keys)...)
    	m.ext[:spineopt].extras[:last_solve_key] = last_solve_key
    end
end

"""
Monte Carlo scenario keys that affect values in the current environment.
"""
function _monte_carlo_scenario_keys(mc_scens)
	pval_key_iter = (
		key
		for p in parameters(SpineOpt)
		for ind in indices_as_tuples(p)
		for key in _map_keys(p(; ind..., _strict=false))
	)
	[
		scenario_key
		for (scenario_key, scenario_values) in mc_scens
		if any(!isdisjoint(key, Symbol.(scenario_values)) for key in pval_key_iter)
	]
end

_map_keys(map::Map) = keys(indexed_values(map))
_map_keys(map) = ()

function _set_monte_carlo_scenario(scen_id)
	for (k, v) in pairs(scen_id)
		if haskey(_monte_carlo_scenario, k)
			_monte_carlo_scenario[k][] = Symbol(v)
		else
			_monte_carlo_scenario[k] = Ref(Symbol(v))
		end
	end
end

needs_auto_updating(::Val{:monte_carlo_algorithm}) = true

algo_kwargs(m, ::Val{:monte_carlo_algorithm}) = (k => (current_window(m) => v) for (k, v) in _monte_carlo_scenario)

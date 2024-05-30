#############################################################################
# Copyright (C) 2017 - 2024  Spine Project
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
	for stage_m in values(m.ext[:spineopt].model_by_stage)
        add_event_handler!(_set_sp_solution!, stage_m, :window_about_to_solve)
        add_event_handler!(_save_sp_solution!, stage_m, :window_solved)
    end
	scenario_keys = keys(mc_scens)
	for (k, scenario_values) in enumerate(Iterators.product(values(mc_scens)...))
		scen_id = (; zip(scenario_keys, scenario_values)...)
		_set_monte_carlo_scenario(scen_id)
		k == 1 && build_model!(m; log_level)
		solve_model!(
			m; log_level, update_names, output_suffix=scen_id, log_prefix="Monte Carlo scenario $k $scen_id - ",
        ) || @warn "Monte Carlo scenario $scen_id failed to solve, moving on..."
	end
    write_report(m, url_out; alternative, log_level)
end

_check_monte_carlo_scenarios(_mc_scens) = error(
	"`monte_carlo_scenarios` must be a map from scenario key, to array of scenario values"
)
_check_monte_carlo_scenarios(mc_scens::Map{Symbol,V}) where {V<:Vector} = nothing

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

algo_kwargs(m, ::Val{:monte_carlo_algorithm}) = Dict(k => (current_window(m) => v) for (k, v) in _monte_carlo_scenario)

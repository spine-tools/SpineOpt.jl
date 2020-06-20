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

function _is_time_slice_set_equal(ts_a, ts_b)
	length(ts_a) == length(ts_b) && all((start(a), end_(a)) == (start(b), end_(b)) for (a, b) in zip(ts_a, ts_b))
end

@testset "temporal structure" begin
	url_in = "sqlite:///$(@__DIR__)/test.sqlite"
	test_data = Dict(
		:objects => [
			["model", "instance"], 
			["node", "only_node"],
			["temporal_block", "block_a"],
			["temporal_block", "block_b"],
		],
		:relationships => [
			["node__temporal_block", ["only_node", "block_a"]],
			["node__temporal_block", ["only_node", "block_b"]],
		],
		:object_parameter_values => [
			["model", "instance", "model_start", Dict("type" => "date_time", "data" => "2000-01-01T00:00:00")],
			["model", "instance", "model_end", Dict("type" => "date_time", "data" => "2006-01-01T00:00:00")],
		]
	)
	@testset "one_two_hourly" begin
		_load_template(url_in)
		db_api.import_data_to_url(url_in; test_data...)
		object_parameter_values = [
			["temporal_block", "block_a", "resolution", Dict("type" => "duration", "data" => "1Y")],
			["temporal_block", "block_b", "resolution", Dict("type" => "duration", "data" => "2Y")],
		]
		db_api.import_data_to_url(url_in; object_parameter_values=object_parameter_values)
		using_spinedb(url_in, SpineOpt)
		SpineOpt.generate_temporal_structure()
		observed_ts_a = time_slice(temporal_block=temporal_block(:block_a))
		observed_ts_b = time_slice(temporal_block=temporal_block(:block_b))
		@test length(observed_ts_a) == 6
		@test length(observed_ts_b) == 3
		expected_ts_a = [TimeSlice(DateTime(i), DateTime(i + 1)) for i in 2000:2005]
		expected_ts_b = [TimeSlice(DateTime(i), DateTime(i + 2)) for i in 2000:2:2005]
		@test _is_time_slice_set_equal(expected_ts_a, observed_ts_a)
		@test _is_time_slice_set_equal(expected_ts_b, observed_ts_b)
		@testset for (i, t) in enumerate(observed_ts_a)
			j = round(Int, i / 2, RoundUp)
			expected_t_before_t = if (i == length(observed_ts_a))
				[]
			else
				if (i % 2 != 0) 
					[observed_ts_a[i + 1]]
				else
					[observed_ts_a[i + 1], observed_ts_b[j + 1]]
				end
			end
			observed_t_before_t = t_before_t(t_before=t)
			@test _is_time_slice_set_equal(expected_t_before_t, observed_t_before_t)
			expected_t_in_t = [t, observed_ts_b[j]]
			observed_t_in_t = t_in_t(t_short=t)
			@test _is_time_slice_set_equal(expected_t_in_t, observed_t_in_t)
			expected_t_overlaps_t = [t, observed_ts_b[j]]
			observed_t_overlaps_t = t_overlaps_t(t)
			@test _is_time_slice_set_equal(expected_t_overlaps_t, observed_t_overlaps_t)
		end
		@testset for (j, t) in enumerate(observed_ts_b)
			expected_t_before_t = if (j == length(observed_ts_b))
				[]
			else
				[observed_ts_a[2 * j + 1], observed_ts_b[j + 1]]
			end
			observed_t_before_t = t_before_t(t_before=t)
			@test _is_time_slice_set_equal(expected_t_before_t, observed_t_before_t)
			expected_t_in_t = [t]
			observed_t_in_t = t_in_t(t_short=t)
			@test _is_time_slice_set_equal(expected_t_in_t, observed_t_in_t)
			expected_t_overlaps_t = [observed_ts_a[2 * j - 1], observed_ts_a[2 * j], t]
			observed_t_overlaps_t = t_overlaps_t(t)
			@test _is_time_slice_set_equal(expected_t_overlaps_t, observed_t_overlaps_t)
		end
   	end
end
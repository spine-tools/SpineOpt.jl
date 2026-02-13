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

_is_time_slice_equal(a, b) = (start(a), end_(a)) == (start(b), end_(b))

function _is_time_slice_set_equal(ts_a, ts_b)
    length(ts_a) == length(ts_b) && all(_is_time_slice_equal(a, b) for (a, b) in zip(sort(ts_a), sort(ts_b)))
end

function _model()
    m = Model(; add_bridges = false)
    JuMP.set_string_names_on_creation(m, false)
    m.ext[:spineopt] = SpineOpt.SpineOptExt(first(model()), nothing)
    m
end

function _test_temporal_structure_setup()
    url_in = "sqlite://"
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
        :object_parameter_values =>
            [["model", "instance", "model_start", Dict("type" => "date_time", "data" => "2000-01-01T00:00:00")]],
    )
    _load_test_data(url_in, test_data)
    url_in
end

function _test_discontinuity_at_the_first_time_step()
    # NOTE: This test tests that if a temporal block ends earlier than the optimisation window,
    # nodes associated only to it don't have a node_injection constraint for the first time step.
    # The point is to illustrate this behavior which may not be the optimal one.
    @testset "discontinuity" begin
        url_in = _test_temporal_structure_setup()
        objects = [
            ["node", "another_node"],
        ]
        relationships = [
            ["node__temporal_block", ["another_node", "block_b"]],
        ]
        object_parameter_values = [
            ["model", "instance", "model_end", Dict("type" => "date_time", "data" => "2000-01-02T00:00:00")],
            ["temporal_block", "block_b", "block_end", Dict("type" => "date_time", "data" => "2000-01-01T06:00:00")],
        ]
        SpineInterface.import_data(
            url_in; objects=objects, relationships=relationships, object_parameter_values=object_parameter_values
        )
        using_spinedb(url_in, SpineOpt)
        using_spinedb(url_in, SpineOpt)
        m = _model()
        generate_temporal_structure!(m)
        t = first(time_slice(m))
        ts = collect(
            x.t_after for x in SpineOpt.node_dynamic_time_indices(m) if x.node.name == :another_node
        )
        @test !(t in ts)
    end
end

function _test_representative_time_slice()
    @testset "representative_time_slice" begin
        url_in = _test_temporal_structure_setup()
        representative_periods_mapping = Dict(
            "type" => "map",
            "index_type" => "date_time",
            "data" => Dict(
                "2000-01-01T00:00:00" => "rep_blk1",
                "2000-01-01T06:00:00" => "rep_blk2",
                "2000-01-01T12:00:00" => "rep_blk2",
                "2000-01-01T18:00:00" => "rep_blk1",
            )
        )
        objects = [["temporal_block", "rep_blk1"], ["temporal_block", "rep_blk2"]]
        relationships = [
            ["model__temporal_block", ["instance", "rep_blk1"]],
            ["model__temporal_block", ["instance", "rep_blk2"]],
        ]
        object_parameter_values = [
            ["temporal_block", "block_a", "representative_periods_mapping", representative_periods_mapping],
            ["temporal_block", "rep_blk1", "block_start", Dict("type" => "date_time", "data" => "2000-01-01T00:00:00")],
            ["temporal_block", "rep_blk1", "block_end", Dict("type" => "date_time", "data" => "2000-01-01T06:00:00")],
            ["temporal_block", "rep_blk1", "resolution", Dict("type" => "duration", "data" => "6h")],
            ["temporal_block", "rep_blk2", "block_start", Dict("type" => "date_time", "data" => "2000-01-01T12:00:00")],
            ["temporal_block", "rep_blk2", "block_end", Dict("type" => "date_time", "data" => "2000-01-01T18:00:00")],
            ["temporal_block", "rep_blk2", "resolution", Dict("type" => "duration", "data" => "6h")]
        ]
        SpineInterface.import_data(
            url_in; objects=objects, relationships=relationships, object_parameter_values=object_parameter_values
        )
        using_spinedb(url_in, SpineOpt)
        m = _model()
        generate_temporal_structure!(m)
        rep_blk1_t = only(SpineOpt.time_slice(m, temporal_block=temporal_block(:rep_blk1)))
        rep_blk2_t = only(SpineOpt.time_slice(m, temporal_block=temporal_block(:rep_blk2)))
        m_start = model_start(model=first(model(model_type=:spineopt_standard)))
        for t in SpineOpt.time_slice(m, temporal_block=temporal_block(:block_a))
            t_end = end_(t)
            if t_end <= m_start + Hour(6)
                @test _representative_time_slice(m, t) == rep_blk1_t
            elseif t_end <= m_start + Hour(12)
                @test _representative_time_slice(m, t) == rep_blk2_t
            elseif t_end <= m_start + Hour(18)
                @test _representative_time_slice(m, t) == rep_blk2_t
            elseif t_end <= m_start + Hour(24)
                @test _representative_time_slice(m, t) == rep_blk1_t
            else
                @test _representative_time_slice(m, t) == t
            end
        end
    end
end

function _representative_time_slice(m, t)
    blk_coef = SpineOpt.representative_block_coefficients(m, t)
    isempty(blk_coef) && return t
    blk, coef = only(blk_coef)
    @assert isone(coef)
    only(time_slice(m; temporal_block=blk))
end

function _test_zero_resolution()
    @testset "zero_resolution" begin
        url_in = _test_temporal_structure_setup()
        object_parameter_values = [
            ["model", "instance", "model_end", Dict("type" => "date_time", "data" => "2000-01-02T00:00:00")],
            ["temporal_block", "block_a", "resolution", 0],
        ]
        SpineInterface.import_data(url_in; object_parameter_values=object_parameter_values)
        using_spinedb(url_in, SpineOpt)
        err_msg = "`resolution` of temporal block `block_a` cannot be zero!"
        m = _model()
        @test_throws ErrorException(err_msg) generate_temporal_structure!(m)
    end
end

function _test_block_start()
    @testset "block_start" begin
        url_in = _test_temporal_structure_setup()
        objects = [["temporal_block", "block_c"]]
        relationships =
            [["model__temporal_block", ["instance", "block_c"]], ["node__temporal_block", ["only_node", "block_c"]]]
        object_parameter_values = [
            ["model", "instance", "model_end", Dict("type" => "date_time", "data" => "2000-01-03T00:00:00")],
            ["temporal_block", "block_a", "resolution", Dict("type" => "duration", "data" => "1D")],
            ["temporal_block", "block_b", "resolution", Dict("type" => "duration", "data" => "1D")],
            ["temporal_block", "block_c", "resolution", Dict("type" => "duration", "data" => "1D")],
            ["temporal_block", "block_a", "block_start", Dict("type" => "duration", "data" => "1D")],
            ["temporal_block", "block_b", "block_start", Dict("type" => "date_time", "data" => "2000-01-01T15:36:00")],
            ["temporal_block", "block_c", "block_start", nothing],
        ]
        SpineInterface.import_data(
            url_in;
            objects=objects,
            relationships=relationships,
            object_parameter_values=object_parameter_values,
        )
        using_spinedb(url_in, SpineOpt)
        m = _model()
        generate_temporal_structure!(m)
        @test start(first(time_slice(m; temporal_block=temporal_block(:block_a)))) == DateTime("2000-01-02T00:00:00")
        @test start(first(time_slice(m; temporal_block=temporal_block(:block_b)))) == DateTime("2000-01-01T15:36:00")
        @test start(first(time_slice(m; temporal_block=temporal_block(:block_c)))) == DateTime("2000-01-01T00:00:00")
    end
end

function _test_block_end()
    @testset "block_end" begin
        url_in = _test_temporal_structure_setup()
        objects = [["temporal_block", "block_c"]]
        relationships =
            [["model__temporal_block", ["instance", "block_c"]], ["node__temporal_block", ["only_node", "block_c"]]]
        object_parameter_values = [
            ["model", "instance", "model_end", Dict("type" => "date_time", "data" => "2000-01-03T00:00:00")],
            ["temporal_block", "block_a", "resolution", Dict("type" => "duration", "data" => "1D")],
            ["temporal_block", "block_b", "resolution", Dict("type" => "duration", "data" => "1D")],
            ["temporal_block", "block_c", "resolution", Dict("type" => "duration", "data" => "1D")],
            ["temporal_block", "block_a", "block_end", Dict("type" => "duration", "data" => "1D")],
            ["temporal_block", "block_b", "block_end", Dict("type" => "date_time", "data" => "2000-01-01T15:36:00")],
            ["temporal_block", "block_c", "block_end", nothing],
        ]
        SpineInterface.import_data(
            url_in;
            objects=objects,
            relationships=relationships,
            object_parameter_values=object_parameter_values,
        )
        using_spinedb(url_in, SpineOpt)
        m = _model()
        generate_temporal_structure!(m)
        @test end_(last(time_slice(m; temporal_block=temporal_block(:block_a)))) == DateTime("2000-01-02T00:00:00")
        @test end_(last(time_slice(m; temporal_block=temporal_block(:block_b)))) == DateTime("2000-01-01T15:36:00")
        @test end_(last(time_slice(m; temporal_block=temporal_block(:block_c)))) == DateTime("2000-01-03T00:00:00")
    end
end

function _test_one_two_four_even()
    @testset "one_two_four_even" begin
        url_in = _test_temporal_structure_setup()
        objects = [["temporal_block", "block_c"]]
        relationships =
            [["model__temporal_block", ["instance", "block_c"]], ["node__temporal_block", ["only_node", "block_c"]]]
        object_parameter_values = [
            ["model", "instance", "model_end", Dict("type" => "date_time", "data" => "2004-01-01T00:00:00")],
            ["temporal_block", "block_a", "resolution", Dict("type" => "duration", "data" => "1Y")],
            ["temporal_block", "block_b", "resolution", Dict("type" => "duration", "data" => "2Y")],
            ["temporal_block", "block_c", "resolution", Dict("type" => "duration", "data" => "4Y")],
        ]
        SpineInterface.import_data(
            url_in;
            objects=objects,
            relationships=relationships,
            object_parameter_values=object_parameter_values,
        )
        using_spinedb(url_in, SpineOpt)
        m = _model()
        generate_temporal_structure!(m)
        observed_ts_a = time_slice(m; temporal_block=temporal_block(:block_a))
        observed_ts_b = time_slice(m; temporal_block=temporal_block(:block_b))
        observed_ts_c = time_slice(m; temporal_block=temporal_block(:block_c))
        expected_ts_a = [TimeSlice(DateTime(i), DateTime(i + 1)) for i in 2000:2003]
        expected_ts_b = [TimeSlice(DateTime(i), DateTime(i + 2)) for i in 2000:2:2003]
        expected_ts_c = [TimeSlice(DateTime(2000), DateTime(2004))]
        @test _is_time_slice_set_equal(observed_ts_a, expected_ts_a)
        @test _is_time_slice_set_equal(observed_ts_b, expected_ts_b)
        @test _is_time_slice_set_equal(observed_ts_c, expected_ts_c)
        a1, a2, a3, a4 = observed_ts_a
        b1, b2 = observed_ts_b
        c1 = observed_ts_c[1]
        expected_t_before_t_a1 = [a2]
        expected_t_before_t_a2 = [a3, b2]
        expected_t_before_t_a3 = [a4]
        expected_t_before_t_a4 = []
        expected_t_before_t_b1 = [a3, b2]
        expected_t_before_t_b2 = []
        expected_t_before_t_c1 = []
        @test _is_time_slice_set_equal(t_before_t(m; t_before=a1), expected_t_before_t_a1)
        @test _is_time_slice_set_equal(t_before_t(m; t_before=a2), expected_t_before_t_a2)
        @test _is_time_slice_set_equal(t_before_t(m; t_before=a3), expected_t_before_t_a3)
        @test _is_time_slice_set_equal(t_before_t(m; t_before=a4), expected_t_before_t_a4)
        @test _is_time_slice_set_equal(t_before_t(m; t_before=b1), expected_t_before_t_b1)
        @test _is_time_slice_set_equal(t_before_t(m; t_before=b2), expected_t_before_t_b2)
        @test _is_time_slice_set_equal(t_before_t(m; t_before=c1), expected_t_before_t_c1)
        expected_t_in_t_a1 = [a1, b1, c1]
        expected_t_in_t_a2 = [a2, b1, c1]
        expected_t_in_t_a3 = [a3, b2, c1]
        expected_t_in_t_a4 = [a4, b2, c1]
        expected_t_in_t_b1 = [b1, c1]
        expected_t_in_t_b2 = [b2, c1]
        expected_t_in_t_c1 = [c1]
        @test _is_time_slice_set_equal(t_in_t(m; t_short=a1), expected_t_in_t_a1)
        @test _is_time_slice_set_equal(t_in_t(m; t_short=a2), expected_t_in_t_a2)
        @test _is_time_slice_set_equal(t_in_t(m; t_short=a3), expected_t_in_t_a3)
        @test _is_time_slice_set_equal(t_in_t(m; t_short=a4), expected_t_in_t_a4)
        @test _is_time_slice_set_equal(t_in_t(m; t_short=b1), expected_t_in_t_b1)
        @test _is_time_slice_set_equal(t_in_t(m; t_short=b2), expected_t_in_t_b2)
        @test _is_time_slice_set_equal(t_in_t(m; t_short=c1), expected_t_in_t_c1)
        expected_t_overlaps_t_a1 = [a1, b1, c1]
        expected_t_overlaps_t_a2 = [a2, b1, c1]
        expected_t_overlaps_t_a3 = [a3, b2, c1]
        expected_t_overlaps_t_a4 = [a4, b2, c1]
        expected_t_overlaps_t_b1 = [a1, a2, b1, c1]
        expected_t_overlaps_t_b2 = [a3, a4, b2, c1]
        expected_t_overlaps_t_c1 = [a1, a2, a3, a4, b1, b2, c1]
        @test _is_time_slice_set_equal(t_overlaps_t(m; t=a1), expected_t_overlaps_t_a1)
        @test _is_time_slice_set_equal(t_overlaps_t(m; t=a2), expected_t_overlaps_t_a2)
        @test _is_time_slice_set_equal(t_overlaps_t(m; t=a3), expected_t_overlaps_t_a3)
        @test _is_time_slice_set_equal(t_overlaps_t(m; t=a4), expected_t_overlaps_t_a4)
        @test _is_time_slice_set_equal(t_overlaps_t(m; t=b1), expected_t_overlaps_t_b1)
        @test _is_time_slice_set_equal(t_overlaps_t(m; t=b2), expected_t_overlaps_t_b2)
        @test _is_time_slice_set_equal(t_overlaps_t(m; t=c1), expected_t_overlaps_t_c1)
    end
end

function _test_two_three_uneven()
    @testset "two_three_uneven" begin
        url_in = _test_temporal_structure_setup()
        object_parameter_values = [
            ["model", "instance", "model_end", Dict("type" => "date_time", "data" => "2006-01-01T00:00:00")],
            ["temporal_block", "block_a", "resolution", Dict("type" => "duration", "data" => "2Y")],
            ["temporal_block", "block_b", "resolution", Dict("type" => "duration", "data" => "3Y")],
        ]
        SpineInterface.import_data(url_in; object_parameter_values=object_parameter_values)
        using_spinedb(url_in, SpineOpt)
        m = _model()
        generate_temporal_structure!(m)
        observed_ts_a = time_slice(m; temporal_block=temporal_block(:block_a))
        observed_ts_b = time_slice(m; temporal_block=temporal_block(:block_b))
        expected_ts_a = [TimeSlice(DateTime(i), DateTime(i + 2)) for i in 2000:2:2005]
        expected_ts_b = [TimeSlice(DateTime(i), DateTime(i + 3)) for i in 2000:3:2005]
        @test _is_time_slice_set_equal(observed_ts_a, expected_ts_a)
        @test _is_time_slice_set_equal(observed_ts_b, expected_ts_b)
        a1, a2, a3 = observed_ts_a
        b1, b2 = observed_ts_b
        expected_t_before_t_a1 = [a2]
        expected_t_before_t_a2 = [a3]
        expected_t_before_t_a3 = []
        expected_t_before_t_b1 = [b2]
        expected_t_before_t_b2 = []
        @test _is_time_slice_set_equal(t_before_t(m; t_before=a1), expected_t_before_t_a1)
        @test _is_time_slice_set_equal(t_before_t(m; t_before=a2), expected_t_before_t_a2)
        @test _is_time_slice_set_equal(t_before_t(m; t_before=a3), expected_t_before_t_a3)
        @test _is_time_slice_set_equal(t_before_t(m; t_before=b1), expected_t_before_t_b1)
        @test _is_time_slice_set_equal(t_before_t(m; t_before=b2), expected_t_before_t_b2)
        expected_t_in_t_a1 = [a1, b1]
        expected_t_in_t_a2 = [a2]
        expected_t_in_t_a3 = [a3, b2]
        expected_t_in_t_b1 = [b1]
        expected_t_in_t_b2 = [b2]
        @test _is_time_slice_set_equal(t_in_t(m; t_short=a1), expected_t_in_t_a1)
        @test _is_time_slice_set_equal(t_in_t(m; t_short=a2), expected_t_in_t_a2)
        @test _is_time_slice_set_equal(t_in_t(m; t_short=a3), expected_t_in_t_a3)
        @test _is_time_slice_set_equal(t_in_t(m; t_short=b1), expected_t_in_t_b1)
        @test _is_time_slice_set_equal(t_in_t(m; t_short=b2), expected_t_in_t_b2)
        expected_t_overlaps_t_a1 = [a1, b1]
        expected_t_overlaps_t_a2 = [a2, b1, b2]
        expected_t_overlaps_t_a3 = [a3, b2]
        expected_t_overlaps_t_b1 = [a1, a2, b1]
        expected_t_overlaps_t_b2 = [a2, a3, b2]
        @test _is_time_slice_set_equal(t_overlaps_t(m; t=a1), expected_t_overlaps_t_a1)
        @test _is_time_slice_set_equal(t_overlaps_t(m; t=a2), expected_t_overlaps_t_a2)
        @test _is_time_slice_set_equal(t_overlaps_t(m; t=a3), expected_t_overlaps_t_a3)
        @test _is_time_slice_set_equal(t_overlaps_t(m; t=b1), expected_t_overlaps_t_b1)
        @test _is_time_slice_set_equal(t_overlaps_t(m; t=b2), expected_t_overlaps_t_b2)
    end
end

function _test_gaps()
    @testset "gaps" begin
        url_in = _test_temporal_structure_setup()
        objects = [["temporal_block", "block_c"]]
        relationships =
            [["model__temporal_block", ["instance", "block_c"]], ["node__temporal_block", ["only_node", "block_c"]]]
        object_parameter_values = [
            ["model", "instance", "model_end", Dict("type" => "date_time", "data" => "2007-01-11T00:00:00")],
            ["temporal_block", "block_a", "resolution", Dict("type" => "duration", "data" => "1Y")],
            ["temporal_block", "block_b", "resolution", Dict("type" => "duration", "data" => "1Y")],
            ["temporal_block", "block_c", "resolution", Dict("type" => "duration", "data" => "1Y")],
            ["temporal_block", "block_b", "block_start", Dict("type" => "duration", "data" => "4Y")],
            ["temporal_block", "block_c", "block_start", Dict("type" => "duration", "data" => "8Y")],
            ["temporal_block", "block_a", "block_end", Dict("type" => "duration", "data" => "2Y")],
            ["temporal_block", "block_b", "block_end", Dict("type" => "duration", "data" => "6Y")],
            ["temporal_block", "block_c", "block_end", Dict("type" => "duration", "data" => "10Y")],
        ]
        SpineInterface.import_data(
            url_in;
            objects=objects,
            relationships=relationships,
            object_parameter_values=object_parameter_values,
        )
        using_spinedb(url_in, SpineOpt)
        m = _model()
        generate_temporal_structure!(m)
        observed_ts_a = time_slice(m; temporal_block=temporal_block(:block_a))
        observed_ts_b = time_slice(m; temporal_block=temporal_block(:block_b))
        observed_ts_c = time_slice(m; temporal_block=temporal_block(:block_c))
        expected_ts_a = [TimeSlice(DateTime(2000 + i), DateTime(2000 + i + 1)) for i in 0:1]
        expected_ts_b = [TimeSlice(DateTime(2004 + i), DateTime(2004 + i + 1)) for i in 0:1]
        expected_ts_c = [TimeSlice(DateTime(2008 + i), DateTime(2008 + i + 1)) for i in 0:1]
        @test _is_time_slice_set_equal(observed_ts_a, expected_ts_a)
        @test _is_time_slice_set_equal(observed_ts_b, expected_ts_b)
        @test _is_time_slice_set_equal(observed_ts_c, expected_ts_c)
        a1, a2 = observed_ts_a
        b1, b2 = observed_ts_b
        c1, c2 = observed_ts_c
        @test _is_time_slice_set_equal(t_before_t(m; t_before=a1), [a2])
        @test _is_time_slice_set_equal(t_before_t(m; t_before=a2), [b1])
        @test _is_time_slice_set_equal(t_before_t(m; t_before=b1), [b2])
        @test _is_time_slice_set_equal(t_before_t(m; t_before=b2), [c1])
        @test _is_time_slice_set_equal(t_before_t(m; t_before=c1), [c2])
        @test _is_time_slice_set_equal(t_before_t(m; t_before=c2), [])
        @test _is_time_slice_set_equal(t_in_t(m; t_short=a1), [a1])
        @test _is_time_slice_set_equal(t_in_t(m; t_short=a2), [a2])
        @test _is_time_slice_set_equal(t_in_t(m; t_short=b1), [b1])
        @test _is_time_slice_set_equal(t_in_t(m; t_short=b2), [b2])
        @test _is_time_slice_set_equal(t_in_t(m; t_short=c1), [c1])
        @test _is_time_slice_set_equal(t_in_t(m; t_short=c2), [c2])
        @test _is_time_slice_set_equal(t_overlaps_t(m; t=a1), [a1])
        @test _is_time_slice_set_equal(t_overlaps_t(m; t=a2), [a2])
        @test _is_time_slice_set_equal(t_overlaps_t(m; t=b1), [b1])
        @test _is_time_slice_set_equal(t_overlaps_t(m; t=b2), [b2])
        @test _is_time_slice_set_equal(t_overlaps_t(m; t=c1), [c1])
        @test _is_time_slice_set_equal(t_overlaps_t(m; t=c2), [c2])
        ab1 = TimeSlice(DateTime(2002), DateTime(2003))
        ab2 = TimeSlice(DateTime(2003), DateTime(2004))
        @test _is_time_slice_equal(to_time_slice(m; t=ab1)[1], b1)
        @test _is_time_slice_equal(to_time_slice(m; t=ab2)[1], b1)
        bc1 = TimeSlice(DateTime(2006), DateTime(2007))
        bc2 = TimeSlice(DateTime(2007), DateTime(2008))
        @test _is_time_slice_equal(to_time_slice(m; t=bc1)[1], c1)
        @test _is_time_slice_equal(to_time_slice(m; t=bc2)[1], c1)
    end
end

function _test_to_time_slice_with_rolling()
    @testset "to_time_slice with rolling" begin
        url_in = _test_temporal_structure_setup()
        object_parameter_values = [
            ["model", "instance", "model_start", Dict("type" => "date_time", "data" => "2001-01-01T00:00:00")],
            ["model", "instance", "model_end", Dict("type" => "date_time", "data" => "2003-01-01T00:00:00")],
            ["model", "instance", "roll_forward", Dict("type" => "duration", "data" => "1Y")],
            ["temporal_block", "block_a", "resolution", Dict("type" => "duration", "data" => "6M")],
            ["temporal_block", "block_b", "resolution", Dict("type" => "duration", "data" => "6M")],
        ]
        SpineInterface.import_data(url_in; object_parameter_values=object_parameter_values)
        using_spinedb(url_in, SpineOpt)
        m = _model()
        generate_temporal_structure!(m)
        a1, a2 = time_slice(m; temporal_block=temporal_block(:block_a))
        t1 = TimeSlice(DateTime(2001, 1), DateTime(2001, 6))
        t2 = TimeSlice(DateTime(2001, 7), DateTime(2001, 12))
        @test _is_time_slice_equal(to_time_slice(m; t=t1)[1], a1)
        @test _is_time_slice_equal(to_time_slice(m; t=t2)[1], a2)
        roll_temporal_structure!(m, 1)
        t1 = TimeSlice(DateTime(2002, 1), DateTime(2002, 6))
        t2 = TimeSlice(DateTime(2002, 7), DateTime(2002, 12))
        @test _is_time_slice_equal(to_time_slice(m; t=t1)[1], a1)
        @test _is_time_slice_equal(to_time_slice(m; t=t2)[1], a2)
    end
end

function _test_history()
    @testset "history" begin
        url_in = _test_temporal_structure_setup()
        objects = [("unit", "unitA")]
        object_parameter_values = [
            ["model", "instance", "model_end", Dict("type" => "date_time", "data" => "2000-01-02T04:00:00")],
            ["model", "instance", "roll_forward", Dict("type" => "duration", "data" => "3h")],
            ["temporal_block", "block_a", "resolution", Dict("type" => "duration", "data" => "1h")],
            ["temporal_block", "block_b", "resolution", Dict("type" => "duration", "data" => "2h")],
            ["unit", "unitA", "min_up_time", Dict("type" => "duration", "data" => "4h")],
        ]
        SpineInterface.import_data(url_in; objects=objects, object_parameter_values=object_parameter_values)
        using_spinedb(url_in, SpineOpt)
        m = _model()
        generate_temporal_structure!(m)
        block_a = temporal_block(:block_a)
        block_b = temporal_block(:block_b)
        expected_history_time_slice = [
            TimeSlice(DateTime(1999, 12, 31, 20), DateTime(1999, 12, 31, 21), block_b, block_a; duration_unit=Hour),
            TimeSlice(DateTime(1999, 12, 31, 21), DateTime(1999, 12, 31, 22), block_a; duration_unit=Hour),
            TimeSlice(DateTime(1999, 12, 31, 21), DateTime(1999, 12, 31, 23), block_b; duration_unit=Hour),
            TimeSlice(DateTime(1999, 12, 31, 22), DateTime(1999, 12, 31, 23), block_a; duration_unit=Hour),
            TimeSlice(DateTime(1999, 12, 31, 23), DateTime(2000, 1, 1, 00), block_b, block_a; duration_unit=Hour),
        ]
        @test length(history_time_slice(m)) === 5
        @testset for (te, to) in zip(expected_history_time_slice, history_time_slice(m))
            @test te == to
        end
    end
end

function _test_master_temporal_structure()
    @testset "master_temporal_structure" begin
        url_in = _test_temporal_structure_setup()
        res = Hour(6)
        m_start = DateTime(2001, 1, 1)
        rf = Hour(24)
        m_end = m_start + rf
        a_gap = Hour(6)
        b_look_ahead = Hour(12)
        object_parameter_values = [
            ["model", "instance", "model_start", unparse_db_value(m_start)],
            ["model", "instance", "model_end", unparse_db_value(m_end)],
            ["model", "instance", "roll_forward", unparse_db_value(rf)],
            ["temporal_block", "block_a", "resolution", unparse_db_value(res)],
            ["temporal_block", "block_b", "resolution", unparse_db_value(res)],
            ["temporal_block", "block_a", "block_start", unparse_db_value(a_gap)],
            ["temporal_block", "block_a", "block_end", unparse_db_value(rf - a_gap)],
            ["temporal_block", "block_b", "block_end", unparse_db_value(rf + b_look_ahead)],
        ]
        SpineInterface.import_data(url_in; object_parameter_values=object_parameter_values)
        using_spinedb(url_in, SpineOpt)
        m_mp = _model()
        SpineOpt.generate_master_temporal_structure!(m_mp)
        obs_time_slices = time_slice(m_mp)
        block_a, block_b = temporal_block(:block_a), temporal_block(:block_b)
        starts = m_start : res : m_end - res + b_look_ahead
        blocks_ = [(m_start + a_gap <= st < m_start + rf - a_gap) ? (block_a, block_b) : (block_b,) for st in starts]
        exp_time_slices = [TimeSlice(st, st + res, blks...) for (st, blks) in zip(starts, blocks_)]
        @testset for (obs, exp) in zip(obs_time_slices, exp_time_slices)
            @test obs == exp
        end
    end
end

function _test_subwindows()
    @testset "subwindows" begin
        url_in = _test_temporal_structure_setup()
        res = Day(1)
        m_start = DateTime(2001, 1, 1)
        m_end = m_start + Week(1)
        objects = [["temporal_block", "long_block"]]
        object_parameter_values = [
            ["model", "instance", "model_start", unparse_db_value(m_start)],
            ["model", "instance", "model_end", unparse_db_value(m_end)],
            ["temporal_block", "block_a", "has_free_start", true],
            ["temporal_block", "block_b", "has_free_start", true],
            ["temporal_block", "block_a", "resolution", unparse_db_value(res)],
            ["temporal_block", "block_b", "resolution", unparse_db_value(res)],
            ["temporal_block", "block_a", "block_start", unparse_db_value(m_start)],
            ["temporal_block", "block_a", "block_end", unparse_db_value(m_start + Day(1))],
            ["temporal_block", "block_b", "block_start", unparse_db_value(m_start + Day(3))],
            ["temporal_block", "block_b", "block_end", unparse_db_value(m_start + Day(4))],
            ["temporal_block", "long_block", "resolution", unparse_db_value(Week(1))],
        ]
        SpineInterface.import_data(url_in; objects=objects, object_parameter_values=object_parameter_values)
        using_spinedb(url_in, SpineOpt)
        m = _model()
        SpineOpt.generate_temporal_structure!(m)
        obs_time_slices = time_slice(m)
        exp_time_slices = [
            TimeSlice(m_start, m_start + Day(1), temporal_block(:block_a)),
            TimeSlice(m_start, m_start + Week(1), temporal_block(:long_block)),
            TimeSlice(m_start + Day(3), m_start + Day(4), temporal_block(:block_b))
        ]
        @testset for (obs, exp) in zip(obs_time_slices, exp_time_slices)
            @test obs == exp
        end
        obs_hist_time_slices = history_time_slice(m)
        exp_hist_time_slices = [
            TimeSlice(m_start - Week(1), m_start, temporal_block(:long_block)),
            TimeSlice(m_start - Day(1), m_start, temporal_block(:block_a)),
            TimeSlice(m_start + Day(2), m_start + Day(3), temporal_block(:block_b))
        ]
        @testset for (obs, exp) in zip(obs_hist_time_slices, exp_hist_time_slices)
            @test obs == exp
        end
    end
end

@testset "temporal structure" begin
    _test_representative_time_slice()
    _test_zero_resolution()
    _test_block_start()
    _test_block_end()
    _test_one_two_four_even()
    _test_two_three_uneven()
    _test_gaps()
    _test_to_time_slice_with_rolling()
    _test_history()
    _test_master_temporal_structure()
    _test_subwindows()
    _test_discontinuity_at_the_first_time_step()
end

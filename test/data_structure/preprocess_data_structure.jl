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
@testset "process_lossless_bidirectional_connections" begin
    url_in = "sqlite://"
    test_data = Dict(
        :objects => [["connection", "connection_ab"], ["node", "node_a"], ["node", "node_b"]],
        :relationships => [
            ["connection__from_node", ["connection_ab", "node_a"]],
            ["connection__to_node", ["connection_ab", "node_b"]],
        ],
        :object_parameter_values =>
            [["connection", "connection_ab", "connection_type", "connection_type_lossless_bidirectional"]],
    )
    _load_test_data(url_in, test_data)    
    using_spinedb(url_in, SpineOpt)
    SpineOpt.process_lossless_bidirectional_connections()
    conn_ab = connection(:connection_ab)
    n_a = node(:node_a)
    n_b = node(:node_b)
    @test length(connection__from_node()) == 2
    @test isempty(symdiff(connection__from_node(), connection__to_node()))
    @test (connection=conn_ab, node=n_a) in connection__from_node()
    @test (connection=conn_ab, node=n_b) in connection__from_node()
    @test length(connection__node__node()) == 2
    @test (connection=conn_ab, node1=n_a, node2=n_b) in connection__node__node()
    @test (connection=conn_ab, node1=n_b, node2=n_a) in connection__node__node()
    for class in (connection__to_node, connection__from_node) # We need to specify class information, no idea how this used to work.
        @test capacity_to_flow_conversion_factor(class; connection=conn_ab, node=n_a) == 1
        @test capacity_to_flow_conversion_factor(class; connection=conn_ab, node=n_b) == 1
    end
    @test fix_ratio_out_in_connection_flow(connection=conn_ab, node1=n_a, node2=n_b) == 1
    @test fix_ratio_out_in_connection_flow(connection=conn_ab, node1=n_b, node2=n_a) == 1
end
@testset "expand groups" begin
    url_in = "sqlite://"
    test_data = Dict(
        :objects => [
            ["stochastic_structure", "ss"],
            ["node", "node_group_ab"],
            ["node", "node_a"],
            ["node", "node_b"],
            ["unit", "unit_group_ab"],
            ["unit", "unit_a"],
            ["unit", "unit_b"],
        ],
        :object_groups => [
            ["node", "node_group_ab", "node_a"],
            ["node", "node_group_ab", "node_b"],
            ["unit", "unit_group_ab", "unit_a"],
            ["unit", "unit_group_ab", "unit_b"],
        ],
        :relationships => [
            ["node__stochastic_structure", ["node_group_ab", "ss"]],
            ["units_on__stochastic_structure", ["unit_group_ab", "ss"]],
        ],
    )
    _load_test_data(url_in, test_data)    
    using_spinedb(url_in, SpineOpt)
    n_a = node(:node_a)
    n_b = node(:node_b)
    ng_ab = node(:node_group_ab)
    u_a = unit(:unit_a)
    u_b = unit(:unit_b)
    ug_ab = unit(:unit_group_ab)
    ss = stochastic_structure(:ss)
    @test node__stochastic_structure() == [(node=ng_ab, stochastic_structure=ss)]
    @test units_on__stochastic_structure() == [(unit=ug_ab, stochastic_structure=ss)]
    SpineOpt.expand_node__stochastic_structure()
    SpineOpt.expand_units_on__stochastic_structure()
    @test length(node__stochastic_structure()) == 3
    @test length(units_on__stochastic_structure()) == 3
    @test all((node=n, stochastic_structure=ss) in node__stochastic_structure() for n in (ng_ab, n_a, n_b))
    @test all((unit=u, stochastic_structure=ss) in units_on__stochastic_structure() for u in (ug_ab, u_a, u_b))
end
@testset "lossless_bidirectional_capacities" begin
    conn_r = 0.9
    conn_x = 0.1
    conn_cap_ab = 80
    conn_cap_bc = 100
    conn_cap_ca = 150
    url_in = "sqlite://"
    test_data = Dict(
        :objects => [
            ["grid", "electricity"],
            ["model", "instance"],
            ["temporal_block", "hourly"],
            ["temporal_block", "investments_hourly"],
            ["temporal_block", "two_hourly"],
            ["stochastic_structure", "deterministic"],
            ["stochastic_structure", "investments_deterministic"],
            ["stochastic_structure", "stochastic"],
            ["connection", "connection_ab"],
            ["connection", "connection_bc"],
            ["connection", "connection_ca"],
            ["node", "node_a"],
            ["node", "node_b"],
            ["node", "node_c"],
            ["stochastic_scenario", "parent"],
            ["stochastic_scenario", "child"],
        ],
        :relationships => [
            ["connection__from_node", ["connection_ab", "node_a"]],
            ["connection__to_node", ["connection_ab", "node_b"]],
            ["connection__from_node", ["connection_bc", "node_b"]],
            ["connection__to_node", ["connection_bc", "node_c"]],
            ["connection__from_node", ["connection_ca", "node_c"]],
            ["connection__to_node", ["connection_ca", "node_a"]],
            ["node__grid", ["node_a", "electricity"]],
            ["node__grid", ["node_b", "electricity"]],
            ["node__grid", ["node_c", "electricity"]],
            ["model__temporal_block", ["instance", "hourly"]],
            ["model__temporal_block", ["instance", "two_hourly"]],
            ["model__stochastic_structure", ["instance", "deterministic"]],
            ["model__stochastic_structure", ["instance", "stochastic"]],
            ["node__temporal_block", ["node_a", "hourly"]],
            ["node__temporal_block", ["node_b", "two_hourly"]],
            ["node__temporal_block", ["node_c", "hourly"]],
            ["node__stochastic_structure", ["node_a", "stochastic"]],
            ["node__stochastic_structure", ["node_b", "deterministic"]],
            ["node__stochastic_structure", ["node_c", "stochastic"]],
            ["stochastic_structure__stochastic_scenario", ["deterministic", "parent"]],
            ["stochastic_structure__stochastic_scenario", ["stochastic", "parent"]],
            ["stochastic_structure__stochastic_scenario", ["stochastic", "child"]],
            ["stochastic_structure__stochastic_scenario", ["investments_deterministic", "parent"]],
            ["parent_stochastic_scenario__child_stochastic_scenario", ["parent", "child"]],
        ],
        :object_parameter_values => [
            ["model", "instance", "model_start", Dict("type" => "date_time", "data" => "2000-01-01T00:00:00")],
            ["model", "instance", "model_end", Dict("type" => "date_time", "data" => "2000-01-01T02:00:00")],
            ["model", "instance", "duration_unit", "hour"],
            ["model", "instance", "model_type", "spineopt_standard"],
            ["temporal_block", "hourly", "resolution", Dict("type" => "duration", "data" => "1h")],
            ["temporal_block", "two_hourly", "resolution", Dict("type" => "duration", "data" => "2h")],
            ["connection", "connection_ab", "connection_type", "connection_type_lossless_bidirectional"],
            ["connection", "connection_bc", "connection_type", "connection_type_lossless_bidirectional"],
            ["connection", "connection_ca", "connection_type", "connection_type_lossless_bidirectional"],
            ["connection", "connection_ab", "monitoring_active", true],
            ["connection", "connection_ab", "reactance", conn_x],
            ["connection", "connection_ab", "resistance", conn_r],
            ["connection", "connection_bc", "monitoring_active", true],
            ["connection", "connection_bc", "reactance", conn_x],
            ["connection", "connection_bc", "resistance", conn_r],
            ["connection", "connection_ca", "monitoring_active", true],
            ["connection", "connection_ca", "reactance", conn_x],
            ["connection", "connection_ca", "resistance", conn_r],
            ["grid", "electricity", "physics_type", "ptdf_physics"],
            ["node", "node_a", "node_opf_type", "node_opf_type_reference"],
            ["connection", "connection_ca", "contingency_active", true],
            ["model", "instance", "solver_mip", "HiGHS.jl"],
            ["model", "instance", "solver_lp", "HiGHS.jl"],
        ],
        :relationship_parameter_values => [
            ["connection__from_node", ["connection_ab", "node_a"], "capacity_per_connection", conn_cap_ab],
            ["connection__to_node", ["connection_ab", "node_b"], "capacity_per_connection", conn_cap_ab], # How did this work before?!?
            ["connection__from_node", ["connection_bc", "node_b"], "capacity_per_connection", conn_cap_bc],
            ["connection__from_node", ["connection_ca", "node_c"], "capacity_per_connection", conn_cap_ca],
            [
                "stochastic_structure__stochastic_scenario",
                ["stochastic", "parent"],
                "stochastic_scenario_end",
                Dict("type" => "duration", "data" => "1h"),
            ],
        ],
    )
    _load_test_data(url_in, test_data)
    m = run_spineopt(url_in; log_level=0, optimize=false)
    capacities_dict = Dict(
        connection(:connection_ab) => conn_cap_ab,
        connection(:connection_bc) => conn_cap_bc,
        connection(:connection_ca) => conn_cap_ca,
    )
    @testset for (conn, n1, n2) in (
        (connection(:connection_ab), node(:node_a), node(:node_b)),
        (connection(:connection_bc), node(:node_b), node(:node_c)),
        (connection(:connection_ca), node(:node_c), node(:node_a)),
    )
        @test capacity_per_connection(connection=conn, node=n1, direction=direction(:from_node)) == capacities_dict[conn]
        @test capacity_per_connection(connection=conn, node=n1, direction=direction(:to_node)) == capacities_dict[conn]
        @test capacity_per_connection(connection=conn, node=n2, direction=direction(:from_node)) == capacities_dict[conn]
        @test capacity_per_connection(connection=conn, node=n2, direction=direction(:to_node)) == capacities_dict[conn]
    end
    #=
    NOTE!
    These testsets are for the former SpineInterface functions `_reorder_dimensions!()`
    and `_add_dimension!()`, which have been moved to SpineOpt since it's the only
    place where they are necessary.
    =#
    @testset "_reorder_dimensions!" begin
        url_in = "sqlite://"
        institutions = ["KTH", "VTT"]
        countries = ["Sweden", "France", "Finland"]
        data = Dict(
            :object_classes => ["institution", "country"],
            :relationship_classes => [
                ["institution__country__country", ["institution", "country", "country"]]
            ],
            :relationship_parameters => [
                ["institution__country__country", "mobility"],
            ],
            :objects => vcat([["institution", x] for x in institutions], [["country", x] for x in countries]),
            :relationships => [
                ["institution__country__country", ["KTH", "Sweden", "France"]],
                ["institution__country__country", ["KTH", "France", "Sweden"]],
                ["institution__country__country", ["VTT", "Finland", "Sweden"]]
            ],
            :relationship_parameter_values => [
                ["institution__country__country", ["KTH", "Sweden", "France"], "mobility", true],
                ["institution__country__country", ["KTH", "France", "Sweden"], "mobility", false],
                ["institution__country__country", ["VTT", "Finland", "Sweden"], "mobility", true],
            ]
        )
        _load_test_data_without_template(url_in, data)
        Y = Bind()
        using_spinedb(url_in, Y)
        icc = Y.institution__country__country
        icc_orig = deepcopy(icc)
        original_names = [:institution, :country1, :country2]
        reordered_names = [:country1, :institution, :country2]
        ntups_orig = collect(indices(Y.mobility))
        perm = SpineInterface._find_permutation(reordered_names, original_names)
        @test perm == [2, 1, 3]
        @test reordered_names == original_names[perm]
        # Test reordering relationship classes
        SpineOpt._reorder_dimensions!(icc, reordered_names)
        ntups = [
            (country1=Y.country(:France), institution=Y.institution(:KTH), country2=Y.country(:Sweden)),
            (country1=Y.country(:Sweden), institution=Y.institution(:KTH), country2=Y.country(:France)),
            (country1=Y.country(:Finland), institution=Y.institution(:VTT), country2=Y.country(:Sweden)),
        ]
        @test ntups != ntups_orig
        @test icc() == ntups != icc_orig()
        pvs = [
            icc.vertex.parameter_values[ent][:mobility].value
            for ent in icc.vertex.entities
        ]
        @test pvs == [false, true, true]
        @test icc(country1=Y.country(:France)) == [
            (institution=Y.institution(:KTH), country2=Y.country(:Sweden)),
        ]
        @test icc(institution=Y.institution(:KTH)) == [
            (country1=Y.country(:France), country2=Y.country(:Sweden)),
            (country1=Y.country(:Sweden), country2=Y.country(:France)),
        ]
        @test icc(country2=Y.country(:Sweden)) == [
            (country1=Y.country(:France), institution=Y.institution(:KTH)),
            (country1=Y.country(:Finland), institution=Y.institution(:VTT)),
        ]
        @test collect(indices(Y.mobility)) == ntups
        @test Y.mobility(
            country1=Y.country(:Sweden), institution=Y.institution(:KTH), country2=Y.country(:France)
        )
        # Reorder the new classes again to match the original.
        iperm = invperm(perm)
        @test original_names == reordered_names[iperm]
        SpineOpt._reorder_dimensions!(icc, original_names)
        @test icc() == icc_orig()
        @test icc(country1=Y.country(:Sweden)) == [
            (institution=Y.institution(:KTH), country2=Y.country(:France)),
        ] == icc_orig(country1=Y.country(:Sweden))
        @test icc(institution=Y.institution(:VTT)) == [
            (country1=Y.country(:Finland), country2=Y.country(:Sweden)),
        ] == icc_orig(institution=Y.institution(:VTT))
        @test icc(country2=Y.country(:France)) == [
            (institution=Y.institution(:KTH), country1=Y.country(:Sweden)),
        ] == icc_orig(country2=Y.country(:France))
        @test collect(indices(Y.mobility)) == ntups_orig
        @test !(Y.mobility(institution=Y.institution(:KTH), country1=Y.country(:France), country2=Y.country(:Sweden)))
    end
    @testset "_add_dimension!" begin
        url_in = "sqlite://"
        institutions = ["KTH", "VTT"]
        countries = ["Sweden", "France"]
        cities = ["Stockholm", "Paris"]
        data = Dict(
            :object_classes => ["institution", "country", "city", "facility", "relation"],
            :relationship_classes => [
                ["institution__country", ["institution", "country"]],
                ["country__institution", ["country", "institution"]],
                ["facility__facility", ["facility", "facility"]]
            ],
            :superclass_subclasses => [
                ["facility", "institution__country"],
                ["facility", "country__institution"],
            ],
            :relationship_parameters => [
                ["institution__country", "people_count"],
                ["facility__facility", "collaboration", false]
            ],
            :objects => vcat(
                [["institution", x] for x in institutions],
                [["country", x] for x in countries],
                [["city", x] for x in cities],
                [["relation", x] for x in (:in, :houses)]
            ),
            :relationships => [
                ["institution__country", ["KTH", "Sweden"]],
                ["institution__country", ["KTH", "France"]],
                ["country__institution", ["Sweden", "KTH"]],
                ["facility__facility", ["KTH", "Sweden", "Sweden", "KTH"]],
                ["facility__facility", ["Sweden", "KTH", "KTH", "France"]]
            ],
            :relationship_parameter_values => [
                ["institution__country", ["KTH", "Sweden"], "people_count", 3],
                ["institution__country", ["KTH", "France"], "people_count", 1],
            ]
        )
        _load_test_data_without_template(url_in, data)
        Y = Bind()
        using_spinedb(url_in, Y)
        ic1 = Y.institution__country
        ic2 = deepcopy(ic1)
        ic3 = deepcopy(ic1)
        f = Y.facility
        orig_pvs = deepcopy(ic1.vertex.parameter_values)
        # First testing adding one dimension.
        SpineOpt._add_dimension!(ic1, Y.city(:Stockholm))
        SpineOpt._add_dimension!(ic2, :city, Y.city(:Stockholm))
        @test only(ic1.dimension_combinations) == [:institution, :country, :city]
        @test ic1.dimension_combinations == ic1.intact_dimension_combinations != ic3.dimension_combinations
        @test ic2.dimension_combinations == ic2.intact_dimension_combinations
        @test ic1.dimension_combinations == ic2.dimension_combinations
        @test ic1() == ic2() != ic3()
        @test ic1.vertex.parameter_values == ic2.vertex.parameter_values == orig_pvs
        @test ic1(institution=Y.institution(:KTH)) == [
            (country=Y.country(:France), city=Y.city(:Stockholm)),
            (country=Y.country(:Sweden), city=Y.city(:Stockholm)),
        ]
        @test isempty(ic1(institution=Y.institution(:VTT)))
        @test ic1(country=Y.country(:Sweden)) == [(institution=Y.institution(:KTH), city=Y.city(:Stockholm))]
        @test ic1(city=Y.city(:Stockholm)) == [
            (institution=Y.institution(:KTH), country=Y.country(:France)),
            (institution=Y.institution(:KTH), country=Y.country(:Sweden)),
        ]
        @test Y.people_count(institution=Y.institution(:KTH), country=Y.country(:France), city=Y.city(:Stockholm)) == 1
        @test Y.people_count(institution=Y.institution(:KTH), country=Y.country(:Sweden), city=Y.city(:Stockholm)) == 3
        @test collect(indices(Y.people_count)) == [
            (institution=Y.institution(:KTH), country=Y.country(:France), city=Y.city(:Stockholm)),
            (institution=Y.institution(:KTH), country=Y.country(:Sweden), city=Y.city(:Stockholm)),
        ]
        @test f() == [
            (country=Y.country(:Sweden), institution=Y.institution(:KTH)),
            (institution=Y.institution(:KTH), country=Y.country(:France), city=Y.city(:Stockholm)),
            (institution=Y.institution(:KTH), country=Y.country(:Sweden), city=Y.city(:Stockholm))
        ]
        @test f(country=anything, institution=anything, _compact=false) == [
            (country=Y.country(:Sweden), institution=Y.institution(:KTH))
        ]
        @test f(institution=anything, country=anything, _compact=false) == f(city=anything, _compact=false) == [
            (institution=Y.institution(:KTH), country=Y.country(:France), city=Y.city(:Stockholm)),
            (institution=Y.institution(:KTH), country=Y.country(:Sweden), city=Y.city(:Stockholm))
        ]
        # Test adding a second duplicate dimension to ic1
        SpineOpt._add_dimension!(ic1, Y.city(:Paris))
        @test only(ic1.intact_dimension_combinations) == [:institution, :country, :city, :city]
        @test ic1.vertex.parameter_values == ic2.vertex.parameter_values == orig_pvs
        @test ic1(institution=Y.institution(:KTH)) == [
            (country=Y.country(:France), city1=Y.city(:Stockholm), city2=Y.city(:Paris)),
            (country=Y.country(:Sweden), city1=Y.city(:Stockholm), city2=Y.city(:Paris)),
        ]
        @test ic1(country=Y.country(:France)) == [
            (institution=Y.institution(:KTH), city1=Y.city(:Stockholm), city2=Y.city(:Paris)),
        ]
        @test isempty(ic1(city=Y.city(:Stockholm)))
        @test ic1(city1=Y.city(:Stockholm)) == [
            (institution=Y.institution(:KTH), country=Y.country(:France), city2=Y.city(:Paris)),
            (institution=Y.institution(:KTH), country=Y.country(:Sweden), city2=Y.city(:Paris)),
        ]
        @test isempty(ic1(city2=Y.city(:Stockholm)))
        @test ic1(city2=Y.city(:Paris)) == [
            (institution=Y.institution(:KTH), country=Y.country(:France), city1=Y.city(:Stockholm)),
            (institution=Y.institution(:KTH), country=Y.country(:Sweden), city1=Y.city(:Stockholm)),
        ]
        @test Y.people_count(
            institution=Y.institution(:KTH),
            country=Y.country(:France),
            city1=Y.city(:Stockholm),
            city2=Y.city(:Paris),
        ) == 1
        @test Y.people_count(
            institution=Y.institution(:KTH),
            country=Y.country(:Sweden),
            city1=Y.city(:Stockholm),
            city2=Y.city(:Paris),
        ) == 3
        @test collect(indices(Y.people_count)) == [
            (institution=Y.institution(:KTH), country=Y.country(:France), city1=Y.city(:Stockholm), city2=Y.city(:Paris)),
            (institution=Y.institution(:KTH), country=Y.country(:Sweden), city1=Y.city(:Stockholm), city2=Y.city(:Paris)),
        ]
        @test f() == [
            (country=Y.country(:Sweden), institution=Y.institution(:KTH)),
            (institution=Y.institution(:KTH), country=Y.country(:France), city1=Y.city(:Stockholm), city2=Y.city(:Paris)),
            (institution=Y.institution(:KTH), country=Y.country(:Sweden), city1=Y.city(:Stockholm), city2=Y.city(:Paris))
        ]
        # Test adding two duplicate dimensions at once to ic3 to replicate ic1
        SpineOpt._add_dimension!(ic3, [Y.city(:Stockholm), Y.city(:Paris)])
        @test only(ic3.intact_dimension_combinations) == only(ic1.intact_dimension_combinations)
        @test ic3.vertex.parameter_values == ic1.vertex.parameter_values == orig_pvs
        @test ic3() == ic1()
        @test all(
            ic3(;args...) == ic1(;args...)
            for args in [
                (institution=Y.institution(:KTH),),
                (country=Y.country(:France),),
                (city=Y.city(:Stockholm),),
                (city1=Y.city(:Stockholm),),
                (city2=Y.city(:Stockholm),),
                (city2=Y.city(:Paris),),
            ]
        )
        # Test adding dimensions and reordering `facility` subclasses.
        ci = Y.country__institution
        SpineOpt._add_dimension!(ci, [Y.city(:Paris), Y.city(:Stockholm)])
        @test f() == f(country=anything, city1=anything, city2=anything, _compact=false) == [
            (country=Y.country(:Sweden), institution=Y.institution(:KTH), city1=Y.city(:Paris), city2=Y.city(:Stockholm)),
            (institution=Y.institution(:KTH), country=Y.country(:France), city1=Y.city(:Stockholm), city2=Y.city(:Paris)),
            (institution=Y.institution(:KTH), country=Y.country(:Sweden), city1=Y.city(:Stockholm), city2=Y.city(:Paris))
        ]
        SpineOpt._reorder_dimensions!(ci, [:institution, :city1, :country, :city2])
        SpineOpt._reorder_dimensions!(ic1, [:institution, :city1, :country, :city2])
        expected = [
            (institution=Y.institution(:KTH), city1=Y.city(:Paris), country=Y.country(:Sweden), city2=Y.city(:Stockholm)),
            (institution=Y.institution(:KTH), city1=Y.city(:Stockholm), country=Y.country(:France), city2=Y.city(:Paris)),
            (institution=Y.institution(:KTH), city1=Y.city(:Stockholm), country=Y.country(:Sweden), city2=Y.city(:Paris))
        ]
        @test f() == expected
        for (kw, arg) in pairs((institution=anything, city1=anything, country=anything, city2=anything))
            @test f(; kw => arg, :_compact => false) == expected # Superclass calls need to work post reordering.
        end
        # Compound classes are not impacted by changes to their element classes,
        # and need to be manipulated separately:
        ff = Y.facility__facility
        @test ff() == [
            (institution1=Y.institution(:KTH), country1=Y.country(:Sweden), country2=Y.country(:Sweden), institution2=Y.institution(:KTH)),
            (country1=Y.country(:Sweden), institution1=Y.institution(:KTH), institution2=Y.institution(:KTH), country2=Y.country(:France)),
        ]
        dim_perm_map = Dict(
            [:country, :institution, :country, :institution] => [Y.relation(:houses), Y.relation(:houses)],
            [:country, :institution, :institution, :country] => [Y.relation(:houses), Y.relation(:in)],
            [:institution, :country, :country, :institution] => [Y.relation(:in), Y.relation(:houses)],
            [:institution, :country, :institution, :country] => [Y.relation(:in), Y.relation(:in)],
        )
        SpineOpt._add_dimension!(ff, [:relation, :relation], dim_perm_map)
        @test ff() == [
            (institution1=Y.institution(:KTH), country1=Y.country(:Sweden), country2=Y.country(:Sweden), institution2=Y.institution(:KTH), relation1=Y.relation(:in), relation2=Y.relation(:houses)),
            (country1=Y.country(:Sweden), institution1=Y.institution(:KTH), institution2=Y.institution(:KTH), country2=Y.country(:France), relation1=Y.relation(:houses), relation2=Y.relation(:in)),
        ]
        # Test reordering
        SpineOpt._reorder_dimensions!(ff, [:country1, :relation1, :institution1, :country2, :relation2, :institution2])
        @test ff() == [
            (country1=Y.country(:Sweden), relation1=Y.relation(:in), institution1=Y.institution(:KTH), country2=Y.country(:Sweden), relation2=Y.relation(:houses), institution2=Y.institution(:KTH)),
            (country1=Y.country(:Sweden), relation1=Y.relation(:houses), institution1=Y.institution(:KTH), country2=Y.country(:France), relation2=Y.relation(:in), institution2=Y.institution(:KTH)),
        ]
    end
end
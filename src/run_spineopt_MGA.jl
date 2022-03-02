function rerun_spineopt!(
    ::Nothing,
    ::Nothing,
    m::Model,
    url_out::Union{String,Nothing};
    add_user_variables=m -> nothing,
    add_constraints=m -> nothing,
    update_constraints=m -> nothing,
    log_level=3,
    optimize=true,
    alternative_objective = nothing
    )
    outputs = Dict()
    MGA_iterations = 0
    max_MGA_iteration = max_MGA_iterations(model=m.ext[:instance])
    name_MGA_it = :MGA_iteration
    MGA_iteration = SpineOpt.ObjectClass(name_MGA_it, [])
    @eval begin
        MGA_iteration = $MGA_iteration
    end
    @timelog log_level 2 "Preprocessing data structure..." preprocess_data_structure(; log_level=log_level)
    @timelog log_level 2 "Checking data structure..." check_data_structure(; log_level=log_level)
    @timelog log_level 2 "Creating temporal structure..." generate_temporal_structure!(m)
    @timelog log_level 2 "Creating stochastic structure..." generate_stochastic_structure!(m)
    init_model!(m; add_user_variables=add_user_variables, add_constraints=add_constraints, log_level=log_level,alternative_objective=alternative_objective)
    init_outputs!(m)
    k = 1
    while optimize
        @log log_level 1 "Window $k: $(current_window(m))"
        optimize_model!(
            m;
            log_level=log_level,
            iterations=MGA_iterations
        ) || break
        @log log_level 1 "Optimal solution found, objective function value: $(objective_value(m))"
        # @timelog log_level 2 "Saving results..." save_model_results!(outputs, m;iterations=MGA_iterations)
        @timelog log_level 2 "Fixing non-anticipativity values..." fix_non_anticipativity_values!(m)
        if @timelog log_level 2 "Rolling temporal structure...\n" !roll_temporal_structure!(m)
            @timelog log_level 2 " ... Rolling complete\n" break
        end
        update_model!(m; update_constraints=update_constraints, log_level=log_level)
        k += 1
    end
    m

    name_MGA_obj = :objective_value_MGA
    model.parameter_values[m.ext[:instance]][name_MGA_obj] = parameter_value(objective_value(m))
    @eval begin
        $(name_MGA_obj) = $(Parameter(name_MGA_obj, [model]))
    end
    MGA_iterations += 1
    add_MGA_objective_constraint!(m)
    m.ext[:variables][:MGA_objective] = Dict(
               (model = m.ext[:instance],t=current_window(m)) => @variable(m, base_name = _base_name(:MGA_objective,(model = m.ext[:instance],t=current_window(m))), lower_bound=0)
               )
    @objective(m,
            Max,
            m.ext[:variables][:MGA_objective][(model = m.ext[:instance],t=current_window(m))]
            )
    while MGA_iterations <= max_MGA_iteration
        set_objective_MGA_iteration!(m;iteration=MGA_iteration()[end])
        optimize_model!(m;
                    log_level=log_level,
                    iterations=MGA_iterations)  || break
        @log log_level 1 "Optimal solution found, objective function value: $(objective_value(m))"
        save_MGA_objective_values!(m)
        MGA_iterations += 1
    end
    write_report(m, url_out) #... make sure that m hold all solutions; every output get's an MGA extensions!
    m
end

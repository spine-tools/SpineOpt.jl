function rerun_spineopt_MGA_algorithm(
    url_out::String;
    mip_solver=nothing,
    lp_solver=nothing,
    add_user_variables=m -> nothing,
    add_constraints=m -> nothing,
    update_constraints=m -> nothing,
    log_level=3,
    optimize=true,
    use_direct_model=false,
    alternative_objective = nothing
    )
    mip_solver = _default_mip_solver(mip_solver)
    lp_solver = _default_lp_solver(lp_solver)
    outputs = Dict()
    m = create_model(mip_solver, use_direct_model, :spineopt_MGA)
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
    calculate_duals = duals_calculation_needed(m)
    while optimize
        @log log_level 1 "Window $k: $(current_window(m))"
        optimize_model!(
            m;
            log_level=log_level,
            calculate_duals=calculate_duals,
            mip_solver=mip_solver,
            lp_solver=lp_solver,
            use_direct_model=use_direct_model
        ) || break
        @log log_level 1 "Optimal solution found, objective function value: $(objective_value(m))"
        @timelog log_level 2 "Saving results..." save_model_results!(outputs, m;iterations=MGA_iterations)
        @timelog log_level 2 "Fixing non-anticipativity values..." fix_non_anticipativity_values!(m)
        if @timelog log_level 2 "Rolling temporal structure...\n" !roll_temporal_structure!(m)
            @timelog log_level 2 " ... Rolling complete\n" break
        end
        update_model!(m; update_constraints=update_constraints, log_level=log_level)
        k += 1
    end
    m
    #@timelog log_level 2 "Writing report..." write_report(m, url_out)

    name_MGA_obj = :objective_value_MGA
    model.parameter_values[m.ext[:instance]][name_MGA_obj] = parameter_value(objective_value(m))
    @eval begin
        $(name_MGA_obj) = $(Parameter(name_MGA_obj, [model]))
    end
    #save_model_results!(outputs, m;iterations=iterations)#save_MGA_solution!(m; iteration=MGA_iterations) #save the outputs with MGA indication
    MGA_iterations += 1
    add_MGA_objective_constraint!(m)
    @variable(m, MGA_objective >=0)
    while MGA_iterations <= max_MGA_iteration
        set_objective_MGA_iteration!(m)
        optimize_model!(m;
                    log_level=log_level,
                    calculate_duals=calculate_duals,
                    mip_solver=mip_solver,
                    lp_solver=lp_solver,
                    use_direct_model=use_direct_model)
        save_model_results!(outputs, m;iterations=MGA_iterations) #save the outputs with MGA indication; for now everything should be written back (use save_outputs + keyword)
        MGA_iterations += 1
    end
    write_report(m, url_out) #... make sure that m hold all solutions; every output get's an MGA extensions!
    m
end

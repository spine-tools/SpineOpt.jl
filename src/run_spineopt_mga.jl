function rerun_spineopt!(
    ::Nothing,
    ::Nothing,
    m_mga::Model,
    url_out::Union{String,Nothing};
    add_user_variables=m_mga -> nothing,
    add_constraints=m_mga -> nothing,
    update_constraints=m_mga -> nothing,
    log_level=3,
    optimize=true,
    update_names=false,
    alternative_objective=m_mga -> nothing,
)
    outputs = Dict()
    mga_iterations = 0
    max_mga_iteration = max_mga_iterations(model=m_mga.ext[:instance])
    name_mga_it = :mga_iteration
    mga_iteration = SpineOpt.ObjectClass(name_mga_it, [])
    @eval begin
        mga_iteration = $mga_iteration
    end
    @timelog log_level 2 "Preprocessing data structure..." preprocess_data_structure(; log_level=log_level)
    @timelog log_level 2 "Checking data structure..." check_data_structure(; log_level=log_level)
    @timelog log_level 2 "Creating temporal structure..." generate_temporal_structure!(m_mga)
    @timelog log_level 2 "Creating stochastic structure..." generate_stochastic_structure!(m_mga)
    @timelog log_level 2 "Creating economic structure..." generate_economic_structure!(m_mga)
    init_model!(m_mga; add_user_variables=add_user_variables, add_constraints=add_constraints, log_level=log_level,alternative_objective=alternative_objective)
    init_outputs!(m_mga)
    k = 1
    while optimize
        @log log_level 1 "Window $k: $(current_window(m_mga))"
        optimize_model!(
            m_mga;
            log_level=log_level,
            iterations=mga_iterations
        ) || break
        @timelog log_level 2 "Fixing non-anticipativity values..." fix_non_anticipativity_values!(m_mga)
        if @timelog log_level 2 "Rolling temporal structure...\n" !roll_temporal_structure!(m_mga)
            @timelog log_level 2 " ... Rolling complete\n" break
        end
        update_model!(m_mga; update_constraints=update_constraints, log_level=log_level, update_names=update_names)
        k += 1
    end
    @timelog log_level 2 "Writing report..." write_report(m_mga, url_out)
    m_mga
    write_model_file(m_mga, file_name = "first_mga_iteration")
    name_mga_obj = :objective_value_mga
    if termination_status(m_mga) == MOI.INFEASIBLE
        m_mga
    else
        model.parameter_values[m_mga.ext[:instance]][name_mga_obj] = parameter_value(objective_value(m_mga))
        @eval begin
            $(name_mga_obj) = $(Parameter(name_mga_obj, [model]))
        end
        mga_iterations += 1
        @timelog log_level 2 "Setting mga slack-objective constraint..." add_mga_objective_constraint!(m_mga)
        @timelog log_level 2 "Setting mga objective..." set_mga_objective!(m_mga)
        while mga_iterations <= max_mga_iteration
            @timelog log_level 2 "Adding mga differences of $(mga_iteration()[end])..." set_objective_mga_iteration!(m_mga;iteration=mga_iteration()[end])
            #Clear output dicts here; to reduce memory
            for k in keys(m_mga.ext[:outputs])
                m_mga.ext[:outputs][k] = Dict()
            end
            @timelog log_level 2 "Cleaning output dictionary to reduce memory after iteration $(mga_iterations)..." GC.gc()
            @timelog log_level 2 "Solving mga iteration $(mga_iteration()[end])..." optimize_model!(m_mga;
                        log_level=log_level,
                        iterations=mga_iterations)  || break
            @timelog log_level 2 "Saving mga objective of $(mga_iteration()[end])..." save_mga_objective_values!(m_mga)
            @timelog log_level 2 "Writing mga report of $(mga_iteration()[end])..." write_report(m_mga, url_out)
            mga_iterations += 1
        end
        m_mga
    end
end

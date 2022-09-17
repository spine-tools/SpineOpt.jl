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
    alternative="",
    alternative_objective=m_mga -> nothing,
    write_as_roll=0,
    resume_file_path=nothing
)
    outputs = Dict()
    mga_iterations = 0
    max_mga_iteration = max_mga_iterations(model=m_mga.ext[:spineopt].instance)
    name_mga_it = :mga_iteration
    mga_iteration = SpineOpt.ObjectClass(name_mga_it, [])
    @eval begin
        mga_iteration = $mga_iteration
    end
    @timelog log_level 2 "Creating temporal structure..." generate_temporal_structure!(m_mga)
    @timelog log_level 2 "Creating stochastic structure..." generate_stochastic_structure!(m_mga)
    init_model!(
        m_mga;
        add_user_variables=add_user_variables,
        add_constraints=add_constraints,
        log_level=log_level,
        alternative_objective=alternative_objective
    )
    init_outputs!(m_mga)
    k = 1
    while optimize
        @log log_level 1 "Window $k: $(current_window(m_mga))"
        optimize_model!(
            m_mga;
            log_level=log_level,
            iterations=mga_iterations
        ) || break
        @timelog log_level 2 "Applying non-anticipativity constraints..." apply_non_anticipativity_constraints!(m_mga)
        if @timelog log_level 2 "Rolling temporal structure...\n" !roll_temporal_structure!(m_mga)
            @timelog log_level 2 " ... Rolling complete\n" break
        end
        update_model!(m_mga; update_constraints=update_constraints, log_level=log_level, update_names=update_names)
        k += 1
    end
    m_mga
    name_mga_obj = :objective_value_mga
    model.parameter_values[m_mga.ext[:spineopt].instance][name_mga_obj] = parameter_value(objective_value(m_mga))
    @eval begin
        $(name_mga_obj) = $(Parameter(name_mga_obj, [model]))
    end
    mga_iterations += 1
    add_mga_objective_constraint!(m_mga)
    set_mga_objective!(m_mga)
    while mga_iterations <= max_mga_iteration
        set_objective_mga_iteration!(m_mga;iteration=mga_iteration()[end])
        optimize_model!(m_mga;
                    log_level=log_level,
                    iterations=mga_iterations)  || break
        save_mga_objective_values!(m_mga)
        mga_iterations += 1
    end
    write_report(m_mga, url_out; alternative=alternative)
    m_mga
end

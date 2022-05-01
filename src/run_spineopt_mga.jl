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
    mga_weight_alpha = SpineOpt.ObjectClass(:mga_weight_alpha, [])
    @eval begin
        mga_weight_alpha  = $mga_weight_alpha
    end
    @timelog log_level 2 "Preprocessing data structure..." preprocess_data_structure(; log_level=log_level)
    @timelog log_level 2 "Checking data structure..." check_data_structure(; log_level=log_level)
    @timelog log_level 2 "Creating temporal structure..." generate_temporal_structure!(m_mga)
    @timelog log_level 2 "Creating stochastic structure..." generate_stochastic_structure!(m_mga)
    @timelog log_level 2 "Creating economic structure..." generate_economic_structure!(m_mga)
    init_model!(m_mga; add_user_variables=add_user_variables, add_constraints=add_constraints, log_level=log_level,alternative_objective=alternative_objective)
    init_outputs!(m_mga)
    mga_alpha, mga_alpha_steps = define_mga_alpha!()
    k = 1
    while optimize
        @log log_level 1 "Window $k: $(current_window(m_mga))"
        optimize_model!(
            m_mga;
            log_level=log_level,
            iterations=mga_iterations,
            # mga_alpha=mga_alpha,
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
        if !isnothing(mga_alpha_steps)
            for mga_alpha = 0:mga_alpha_steps:1
                    while mga_iterations <= max_mga_iteration
                        mga_it_obj = mga_iteration(Symbol("mga_it_$(mga_iterations-1)"))
                        @timelog log_level 2 "Adding mga differences of $(mga_it_obj)..." set_objective_mga_iteration!(m_mga;iteration=mga_it_obj, mga_alpha=mga_alpha)
                        @timelog log_level 2 "Cleaning output dictionary to reduce memory after iteration $(mga_iterations)..." GC.gc()
                        @timelog log_level 2 "Solving mga iteration $(mga_it_obj)..." optimize_model!(m_mga;
                                    log_level=log_level,
                                    iterations=mga_iterations,
                                    )  || break
                        @timelog log_level 2 "Saving mga objective of $(mga_it_obj)..." save_mga_objective_values!(m_mga)
                        write_model_file(m_mga, file_name = "mga_iteration_$(mga_iteration)__mga_alpha_$(mga_alpha)")
                        ## for each subsequent run:
                        mga_iterations += 1
                    end
                    new_mga_alpha = Symbol(string("mga_alpha_", mga_alpha))
                    if mga_weight_alpha(new_mga_alpha) == nothing
                        new_mga_alpha_i = Object(new_mga_alpha)
                        add_object!(mga_weight_alpha,  new_mga_alpha_i)
                    else
                        new_mga_alpha_i = mga_weight_alpha(new_mga_alpha)
                    end
                    for k in keys(m_mga.ext[:outputs])
                            m_mga.ext[:outputs][k] = _add_key(m_mga.ext[:outputs][k], :mga_weight_alpha, mga_weight_alpha(Symbol("mga_alpha_$(mga_alpha)")))

                    end
                    @timelog log_level 2 "Writing mga report of  mga alpha $(mga_alpha)..." write_report(m_mga, url_out)
                    for k in keys(m_mga.ext[:outputs])
                        try
                            m_mga.ext[:outputs][k] = filter(x -> x[1].mga_iteration == mga_iteration(:mga_it_0),m_mga.ext[:outputs][k])

                           m_mga.ext[:outputs][k] = _drop_key(m_mga.ext[:outputs][k], :mga_weight_alpha)

                       catch
                       end
                    end
                    mga_iterations = 1
                    for cons in
                    [:mga_objective_ub,
                    :mga_diff_ub1,
                    :mga_diff_ub2,
                    :mga_diff_lb1,
                    :mga_diff_lb2]
                        for k in keys(m_mga.ext[:constraints][cons])
                            delete(m_mga,m_mga.ext[:constraints][cons][k])
                        end
                    end
            end
        else
            while mga_iterations <= max_mga_iteration
                @timelog log_level 2 "Adding mga differences of $(mga_iteration()[end])..." set_objective_mga_iteration!(m_mga;iteration=mga_iteration()[end])
                #Clear output dicts here; to reduce memory
                for k in keys(m_mga.ext[:outputs])
                    m_mga.ext[:outputs][k] = Dict()
                end
                @timelog log_level 2 "Cleaning output dictionary to reduce memory after iteration $(mga_iterations)..." GC.gc()
                @timelog log_level 2 "Solving mga iteration $(mga_iteration()[end])..." optimize_model!(m_mga;
                            log_level=log_level,
                            iterations=mga_iterations,
                            mga_alpha=mga_alpha,)  || break
                @timelog log_level 2 "Saving mga objective of $(mga_iteration()[end])..." save_mga_objective_values!(m_mga)
                @timelog log_level 2 "Writing mga report of $(mga_iteration()[end])..." write_report(m_mga, url_out)
                mga_iterations += 1
            end
        end
        m_mga
    end
end

function define_mga_alpha!()
    mga_alpha_steps = nothing
    mga_alpha = nothing
    if !isempty(indices(mga_alpha_step_length))
        if length(collect(indices(mga_alpha_step_length))) >1
            @warn "There is more than one object or relationship class definind mga_alpha_step_length - only one allowed. \n Processing without alpha"
        elseif length(vcat(
            [storages_invested_mga_indices()...,
            connections_invested_mga_indices()...,
            units_invested_mga_indices()...,
            ]
            )) != 2
            @warn "Mga alpha steplength can only be used if the mga objective holds exactly two mga differences. \n Processing without alpha"
        else
            cls_name = collect(indices(mga_alpha_step_length))[1].class_name
            id = collect(indices(mga_alpha_step_length))[1]
            mga_alpha_steps = mga_alpha_step_length(;Dict(cls_name=> id)...)
            println("Alpha steplength of $(id) has been set to $(mga_alpha_steps)")
            mga_alpha = 0
        end
        mga_alpha, mga_alpha_steps
    end
end

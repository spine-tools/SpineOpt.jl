using SpineModel
using SpineInterface
using JuMP
using Dates
using URIParser

include("preprocess_data_structure.jl")
include("timeslice_model.jl")
include("variables.jl")
include("postprocess_results.jl")

function run_timeslicetool(
    url_in::String;
    with_optimizer=optimizer_with_attributes(Cbc.Optimizer, "logLevel" => 0, "ratioGap" => 0.01),
    )
    @info "reading database"
    using_spinedb(url_in)
    @info "processing spine model temporal structure"
    SpineModel.generate_temporal_structure()
    @info "preprocessing data structure"
    window__static_slice = preprocess_data_structure()
    @info "Initializing model..."
    m = Model(with_optimizer)

    m.ext[:variables] = Dict{Symbol,Dict}()
    m.ext[:variables_lb] = Dict{Symbol,Any}()
    m.ext[:variables_ub] = Dict{Symbol,Any}()
    m.ext[:values] = Dict{Symbol,Dict}()
    m.ext[:constraints] = Dict{Symbol,Dict}()

    create_variables!(m)
    set_objective!(m)
    add_constraint_error1!(m)
    add_constraint_error2!(m)
    add_constraint_selected_periods!(m)
    add_constraint_single_weight!(m)
    add_constraint_total_weight!(m)

    optimize!(m)
    if termination_status(m) == MOI.OPTIMAL
        @info "Model sloved. Termination status: $(termination_status(m))"
        postprocess_results!(m, url_in, window__static_slice)
    else
        @info "Unable to find solution (reason: $(termination_status(m)))"
    end

end

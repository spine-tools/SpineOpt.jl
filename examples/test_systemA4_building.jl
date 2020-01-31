# Load modules
using JuMP
using SpineModel
using Cbc

# Custon constraints required for case study A4
function add_constraints(m::Model)
    # Cyclic storage bounds on the first solve
    @fetch stor_state = m.ext[:variables]
    cons = m.ext[:constraints][:stor_cyclic] = Dict()
    filtered_storage__commodity = filter(stor_c -> stor_c.storage in SpineModel.indices(cyclic), storage__commodity())
    stor_start = [first(stor_state_indices(storage=stor, commodity=c)) for (stor, c) in filtered_storage__commodity]
    stor_end = [last(stor_state_indices(storage=stor, commodity=c)) for (stor, c) in filtered_storage__commodity]
    for (stor, c, t_first) in stor_start
        for (stor, c, t_last) in stor_end
            (stor, c, t_first, t_last) in keys(cons) && continue
            cons[stor, c, t_first, t_last] = @constraint(
                m,
                stor_state[stor, c, t_first]
                ==
                stor_state[stor, c, t_last]
            )
        end
    end
end

function update_constraints(m::Model)
    cons = pop!(m.ext[:constraints], :stor_cyclic, nothing)
    cons === nothing && return
    delete.(m, values(cons))
end


# Spine Case Study A4 databases
url_in = "sqlite:///$(@__DIR__)/data/Building_Data_Store.sqlite"

# Run the model from the chosen database
m = run_spinemodel(
    url_in; 
    with_optimizer=with_optimizer(Cbc.Optimizer, logLevel=0, allowableGap=0, ratioGap=0), 
    add_constraints=add_constraints, 
    update_constraints=update_constraints, 
    log_level=2
)

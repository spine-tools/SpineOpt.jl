#############################################################################
# Copyright (C) 2017 - 2018  Spine Project
#
# This file is part of Spine Model.
#
# Spine Model is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Spine Model is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#############################################################################
# Export contents of database into the current session
using JuMP
using SpineModel
using SpineInterface
try
    using Gurobi
catch
    using Cbc
end

# Custon constraint for cyclical boundary conditions for stor_state.
# Simply intended to prevent ridiculous initial temperatures
# without the need to fix them
function constraint_stor_cyclic(m::Model)
    @fetch stor_state = m.ext[:variables]
    constr_dict = m.ext[:constraints][:stor_cyclic] = Dict()
    stor_start = [first(stor_state_indices(storage=stor, commodity=c)) for (stor, c) in storage__commodity()]
    for (stor, c, t_first) in stor_start
        constr_dict[stor, c] = @constraint(
            m,
            stor_state[stor, c, t_first]
            ==
            stor_state[stor, c, time_slice()[end]]
        )
    end
end

# Run the model from the database
db_url = "sqlite:///$(@__DIR__)/data/testsystemA4.sqlite"
m = try
    run_spinemodel(db_url; optimizer=Gurobi.Optimizer, cleanup=false, extend=m->constraint_stor_cyclic(m))
catch
    run_spinemodel(db_url; optimizer=Cbc.Optimizer, cleanup=false, extend=m->constraint_stor_cyclic(m))
end

# Show active variables and constraints
println("*** Active constraints: ***")
for key in keys(m.ext[:constraints])
    !isempty(m.ext[:constraints][key]) && println(key)
end
println("*** Active variables: ***")
for key in keys(m.ext[:variables])
    !isempty(m.ext[:variables][key]) && println(key)
end

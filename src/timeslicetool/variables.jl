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

"""
Create the variables for the model
"""

function create_variables!(m)

        var = m.ext[:variables][:d_error] = Dict{Tuple, JuMP.VariableRef}()
        for (r, b) in resource__block()
                var[r, b] = @variable(m,
                    base_name="d_error[$(r), $(b)]",
                    lower_bound=0
                )
        end

    var = m.ext[:variables][:selected] = Dict{Object, JuMP.VariableRef}()
    for w in window()
            var[w] = @variable(m,
                    base_name="selected[$w]",
                    binary=true
            )
    end

    var = m.ext[:variables][:weight] = Dict{Object, JuMP.VariableRef}()
    for w in window()
            var[w] = @variable(m,
                base_name="weight[$w]",
                lower_bound=0
            )
    end

end

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
    set_objective!(m::Model)

Minimize the total error between target and representative distributions.
"""
function set_objective!(m::Model)
    @fetch d_error = m.ext[:variables]
    @objective(m, Min,
        + sum(
            + representative_period_weight(resource=r) *
                sum(
                    + d_error[r, b]
                    for b in block()
                )
            for r in resource()
        )
    )
end


"""
    add_constraint_error1!(m::Model)

In conjunction with add_constraint_error2, defines the error between
the representative distributions and the target distributions.
"""
function add_constraint_error1!(m::Model)
    @fetch weight, d_error = m.ext[:variables]
    cons = m.ext[:constraints][:error1] = Dict()
    rp = first(representative_period())
    for (r, b) in resource__block()
        cons[r, b] = @constraint(
            m,
            d_error[r, b]
            >=
            + resource_distribution(resource=r, block=b)
            - sum(
                + (  + weight[w]
                     / length(window())
                  ) * resource_distribution_window(resource=r, block=b, window=w)
                  for w in window()
            )
        )
    end
end

"""
    add_constraint_error2!(m::Model)

In conjunction with add_constraint_error1, defines the error between
the representative distributions and the target distributions.
"""
function add_constraint_error2!(m::Model)
    @fetch d_error, weight = m.ext[:variables]
    cons = m.ext[:constraints][:error2] = Dict()
    rp = first(representative_period())
    for (r, b) in resource__block()
        cons[r, b] = @constraint(
            m,
            d_error[r, b]
            >=
            - resource_distribution(resource=r, block=b)
            + sum(
                + ( + weight[w]
                    / length(window())
                ) * resource_distribution_window(resource=r, block=b, window=w)
                for w in window()
            )
        )
    end
end

function add_constraint_selected_periods!(m::Model)
    @fetch selected = m.ext[:variables]
    cons = m.ext[:constraints][:selected_periods] = Dict()
    rp = first(representative_period())
    cons = @constraint(
        m,
        +   sum(
                + selected[w]
                for w in window()
            )
        <=
        + representative_periods(representative_period=rp)
    )
end


function add_constraint_single_weight!(m::Model)
    @fetch weight, selected = m.ext[:variables]
    cons = m.ext[:constraints][:single_weight] = Dict()
    rp = first(representative_period())
    for w in window()
        cons[w] = @constraint(
            m,
            + weight[w]
            <=
            + selected[w] * representative_periods(representative_period=rp) * length(block())
        )
    end
end


function add_constraint_total_weight!(m::Model)
    @fetch weight = m.ext[:variables]
    cons = m.ext[:constraints][:selected_periods]
    rp = first(representative_period())
    cons = @constraint(
        m,
        +   sum(
                + weight[w]
                for w in window()
            )
        ==
        + representative_periods(representative_period=rp) * length(block())
    )
end

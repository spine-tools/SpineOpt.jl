#############################################################################
# Copyright (C) 2017 - 2023  Spine Project
#
# This file is part of SpineOpt.
#
# SpineOpt is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# SpineOpt is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#############################################################################

"""
add_constraint_node_voltages_conic!(m::Model)

Binds the different voltage products together with a second order conic constraint. This is a
relaxation of the original constraint which is an equality constraint.

N.B. This is a second order conic constraint (=nonlinear) and thus unfit for any linear solver.
"""
function add_constraint_node_voltages_conic!(m::Model)
    @fetch node_voltage_squared, node_voltageproduct_cosine, 
        node_voltageproduct_sine = m.ext[:spineopt].variables
    
    m.ext[:spineopt].constraints[:node_voltages_conic] = Dict(
        (node1=n1, node2=n2, stochastic_path=s, t=t) => @constraint(
            m,
            [0.5 * (node_voltage_squared[n1, s, t] + node_voltage_squared[n2, s, t]),
             node_voltageproduct_cosine[n1, n2, s, t],
             node_voltageproduct_sine[n1, n2, s, t],
             0.5 * (node_voltage_squared[n1, s, t] - node_voltage_squared[n2, s, t])
            ] in SecondOrderCone()
            )

        for (n1, n2, s, t) in node_voltageproduct_indices(m)
    )
end

"""
    add_constraint_node_voltages_polyhedron!(m::Model)

    Adds inequality constraints to create the polyhedron 
    around the ellipsoid x^2 + y^2 + 0.5z^2 <= t^2. The inequalities
    are of form
    ([x,y,z] - p * t) ⋅ n <= 0,

    where p is the tangency point on the ellipsoid and n is the surface
    normal of the ellipsoid at the tangency point.
"""
function add_constraint_node_voltages_polyhedron!(m::Model)
    @fetch node_voltage_squared, node_voltageproduct_cosine, 
        node_voltageproduct_sine = m.ext[:spineopt].variables
    
    tangency_points = [(0, 0)] ∪
            [(2.5, fii) for fii in 0:10:359] ∪ 
            [(5, fii) for fii in 0:10:359] ∪ 
            [(10, fii) for fii in 0:20:359] ∪ 
            [(20, fii) for fii in 0:20:359] ∪ 
            [(45, fii) for fii in 0:30:359]

    m.ext[:spineopt].constraints[:node_voltages_conic] = Dict(
        (node1=n1, node2=n2, stochastic_path=s, t=t, theta=theta, fii=fii) => @constraint(
            m, 
            dot([node_voltageproduct_cosine[n1, n2, s, t], 
                node_voltageproduct_sine[n1, n2, s, t],
                0.5 * (node_voltage_squared[n1, s, t] - node_voltage_squared[n2, s, t])]
                - collect(surfacepoint((t=1, theta=theta, fii=fii))) * 
                0.5 * (node_voltage_squared[n1, s, t] + node_voltage_squared[n2, s, t]),
                collect(surfacenormal((t=1, theta=theta, fii=fii))) 
            )
             <= 0
        )
        for (n1, n2, s, t) in node_voltageproduct_indices(m)
            for (theta, fii) in tangency_points
    )
end

function surfacepoint(u::NamedTuple)
    return surfacepoint(u.t, u.theta, u.fii)
end

function surfaceunitpoint(u::NamedTuple)
    return surfacepoint(1, u.theta, u.fii)
end

"""
    surfacenormal(u::NamedTuple)

    Returns the ellipsoid surface normal in cartesian coordinates.
    
    `u`: point coordinates in spherical u = (u.t, u.theta, u.fii)
"""
function surfacenormal(u::NamedTuple)
    p = surfaceunitpoint(u)
    n = (p.x, p.y, 0.5 * 0.5 * p.z)
end

"""
    surfacepoint(r, theta, fii)

    `theta`: angle from x-axis
    `fii`: angle from xz-plane

    Returns the point on the ellipsoid where x and y radius is r and 
    z radius 2r.
"""
function surfacepoint(r, theta, fii)
    z = 2 * r * sin(deg2rad(theta)) * cos(deg2rad(fii))
    y = r * sin(deg2rad(theta)) * sin(deg2rad(fii))
    x = r * cos(deg2rad(theta))
    return (x=x, y=y, z=z)
end


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


@doc raw"""
The different voltage products need to be bound together with a second order 
conic constraint. In SpineOpt a relaxation of the original equality constraint 
is included. The constraint is written for bus (node) pairs which are connected by 
at least one line. Thus in the full SOCP formulation

```math
\begin{aligned}
& \left(v^{node\_voltage\_sq}_{(n_{from},s,t)} - v^{node\_voltage\_sq}_{(n_{to},s,t)}\right)^2  \\
& + \left(v^{node\_voltage\_sin}_{(n_{from},n_{to},s,t)}\right)^2 
+ \left(v^{node\_voltage\_cos}_{(n_{from},n_{to},s,t)}\right)^2 \\
& \leq \left(v^{node\_voltage\_sq}_{(n_{from},s,t)} + v^{node\_voltage\_sq}_{(n_{to},s,t)}\right)^2  \\
& \forall (conn, n_{from}, n_{to}) \in connection\_\_node\_\_node : \exists c \in connection, \; connection\_has\_ac\_flow(c, n_{from}, n_{to})\\
& \forall (s,t)
\end{aligned}
```

Note that this second order conic constraint and thus requires compatible solver.

In the linearized version of SOCP relaxation we create an outer polyhedron to approximate 
the voltage cones. The faces are determined by

```math
\begin{aligned}
& \left( \begin{bmatrix}  v^{node\_voltage\_cos}_{(n_{from},n_{to},s,t)} \\ 
v^{node\_voltage\_sin}_{(n_{from},n_{to},s,t)} \\
v^{node\_voltage\_sq}_{(n_{from},s,t)} - v^{node\_voltage\_sq}_{(n_{to},s,t)} \end{bmatrix} 
- \textbf{p}(\theta,\phi)\, \left(  v^{node\_voltage\_sq}_{(n_{from},s,t)} 
+ v^{node\_voltage\_sq}_{(n_{to},s,t)}\right) \right) \cdot \textbf{n}(\theta,\phi) \le 0.  \\
& \forall (conn, n_{from}, n_{to}) \in connection\_\_node\_\_node : \exists c \in connection, \; connection\_has\_ac\_flow(c, n_{from}, n_{to})\\
& \forall (s,t) \\
& \forall (\theta,\phi)
\end{aligned}


```

where $\theta$ and $\phi$ are the spherical angles in a coordinate system defined by 
the voltage variables. For each set of angles, $\textbf{p}(\theta,\phi)$ is the position 
vector of a hyperplane tangency point on an unit ball and $\textbf{n}(\theta,\phi)$ 
is the surface normal vector of the voltage ellipsoid in that point. 

"""
function add_constraint_node_voltages_conic!(m::Model)
    instance = m.ext[:spineopt].instance
    if ac_opf_model_formulation(model=instance) == :ac_opf_conic
        _add_constraint!(m, :node_voltages_conic, acflow_nodepair_indices, 
            _build_constraint_node_voltages_conic_socp)
    elseif ac_opf_model_formulation(model=instance) == :ac_opf_linear
        _add_constraint!(m, :node_voltages_conic, constraint_node_voltages_conic_indices, 
            _build_constraint_node_voltages_conic)
    end
end

"""
    add_constraint_node_voltages_conic!(m::Model)

    We need to add inequality constraints to create the polyhedron 
    around the ellipsoid x^2 + y^2 + 0.5z^2 <= t^2. The inequalities
    are of form
    ([x,y,z] - p * t) ⋅ n <= 0,

    where p is the tangency point on the ellipsoid and n is the surface
    normal of the ellipsoid at the tangency point.
"""
function _build_constraint_node_voltages_conic(m, n1, n2, s, t, theta, fii)
    @fetch node_voltage_squared, node_voltageproduct_cosine, node_voltageproduct_sine = m.ext[:spineopt].variables

     @build_constraint(
            dot([node_voltageproduct_cosine[n1, n2, s, t], 
                node_voltageproduct_sine[n1, n2, s, t],
                1.0 * (node_voltage_squared[n1, s, t] - node_voltage_squared[n2, s, t])]
                - collect(surfacepoint((t=1, theta=theta, fii=fii))) * 
                0.5 * (node_voltage_squared[n1, s, t] + node_voltage_squared[n2, s, t]),
                collect(surfacenormal((t=1, theta=theta, fii=fii))) 
            )
             <= 0
        )
end


function constraint_node_voltages_conic_indices(m::Model)
    tangency_points = collect(zip(ac_flow_tangency_point_theta(model=instance),
        ac_flow_tangency_point_phi(model=instance)))
    (
        (n1, n2, s, t, theta, fii)
        for (n1, n2, s, t) in acflow_nodepair_indices(m)
                for (theta, fii) in tangency_points
    )
end

@doc raw"""

The different voltage products need to be bound together with a second order 
conic constraint. In SpineOpt a relaxation of the original equality constraint 
is included. The constraint is written for bus (node) pairs which are connected by 
at least one line. Thus in the full SOCP formulation

```math
\begin{aligned}
& \left(v^{node\_voltage\_sq}_{(n_{from},s,t)} - v^{node\_voltage\_sq}_{(n_{to},s,t)}\right)^2  \\
& + \left(v^{node\_voltage\_sin}_{(n_{from},n_{to},s,t)}\right)^2 
+ \left(v^{node\_voltage\_cos}_{(n_{from},n_{to},s,t)}\right)^2 \\
& \leq \left(v^{node\_voltage\_sq}_{(n_{from},s,t)} + v^{node\_voltage\_sq}_{(n_{to},s,t)}\right)^2  \\
& \forall (conn, n_{from}, n_{to}) \in connection\_\_node\_\_node : \exists c \in connection, \; connection\_has\_ac\_flow(c, n_{from}, n_{to})\\
& \forall (s,t)
\end{aligned}
```

No that this second order conic constraint and thus requires compatible solver.
"""
function _build_constraint_node_voltages_conic_socp(m::Model, n1, n2, s, t)
    @fetch node_voltage_squared, node_voltageproduct_cosine, 
        node_voltageproduct_sine = m.ext[:spineopt].variables
    
    @build_constraint(
            [0.5 * (node_voltage_squared[n1, s, t] + node_voltage_squared[n2, s, t]),
             node_voltageproduct_cosine[n1, n2, s, t],
             node_voltageproduct_sine[n1, n2, s, t],
             0.5 * (node_voltage_squared[n1, s, t] - node_voltage_squared[n2, s, t])
            ] in SecondOrderCone()
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


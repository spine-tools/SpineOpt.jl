#
# function flow_indices(;commodity=anything, node=anything, unit=anything, direction=anything, t=anything)
#     unit = expand_unit_group(unit)
#     node = expand_node_group(node)
#     commodity = expand_commodity_group(commodity)
#     [
#         (unit=u, node=n, commodity=c, direction=d, t=t1)
#         for (u, n, c, d, tb) in flow_indices_rc(
#             unit=unit, node=node, commodity=commodity, direction=direction, _compact=false
#         )
#         for t1 in time_slice(temporal_block=tb, t=t)
#     ]
# end
#
# fix_flow_(x) = fix_flow(unit=x.unit, node=x.node, direction=x.direction, t=x.t, _strict=false)
#
# create_variable_flow!(m::Model) = create_variable!(m, :flow, flow_indices; lb=x -> 0)
# fix_variable_flow!(m::Model) = fix_variable!(m, :flow, flow_indices, fix_flow_)
#
#
#
#
#
#

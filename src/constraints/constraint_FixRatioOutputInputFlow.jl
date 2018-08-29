#this function is not executable
function constraint_FixRatioOutputInputFlow(m::Model, v_flow)
    @constraint(m, [u in unit(), t=1:number_of_timesteps(time="timer"); !isnull(p_FixRatioOutputInputFlow(unit=u))],
        + sum(v_flow[c_out, n, u, "out", t] for c_out in commodity(), n in node() if [c_out,n,u,"out"] in generate_CommoditiesNodesUnits())
        ==
        + p_FixRatioOutputInputFlow(u,c_out,c_in)
            * sum(flow[c_in,n, u, "in", t] for c_in in commodity(), n in node() if [c_in,n,u,"in"] in generate_CommoditiesNodesUnits())
    )
end

#idea
# function constraint_FixRatioOutputInputFlow(m::Model, v_flow)
#     @constraint(m, [(u,c1,c2) in unit_commodity_commodity(), t=1:number_of_timesteps(time="timer"); !isnull(p_FixRatioOutputInputFlow(unit=u, commodity1=c1, commodity2=c2))],
#         + sum(v_flow[c_out, n, u, "out", t] for c_out in commodity(), n in node() if [c_out,n,u,"out"] in generate_CommoditiesNodesUnits())
#         ==
#         + p_FixRatioOutputInputFlow(u,c_out,c_in)
#             * sum(flow[c_in,n, u, "in", t] for c_in in commodity(), n in node() if [c_in,n,u,"in"] in generate_CommoditiesNodesUnits())
#     )
# end

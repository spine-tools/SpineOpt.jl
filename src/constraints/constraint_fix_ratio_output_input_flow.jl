# TODO: check if the constraint does what we want
# NOTE: This function does not return a value
function constraint_fix_ratio_output_input_flow(m::Model, flow)
    @constraint(
        m,
        [
            u in unit(),
            c_out in commodity(),
            c_in in commodity(),
            t=1:number_of_timesteps(time="timer");
            fix_ratio_output_input_flow(unit=u, commodity1=c_out, commodity2=c_in) != nothing
        ],
        + sum(flow[c_out, n, u, "out", t] for n in node()
            if [c_out, u, "out"] in commodity__node__unit__direction(node=n))
        ==
        + fix_ratio_output_input_flow(unit=u, commodity1=c_out, commodity2=c_in)
            * sum(flow[c_in, n, u, "in", t] for n in node()
                if [c_in, u, "in"] in commodity__node__unit__direction(node=n))
    )
end

# # idea
# function constraint_FixRatioOutputInputFlow(m::Model, v_flow)
#     @constraint(m, [(u,c1,c2) in unit_commodity_commodity(), t=1:number_of_timesteps(time="timer"); !isnull(p_FixRatioOutputInputFlow(unit=u, commodity1=c1, commodity2=c2))],
#         + sum(v_flow[c_out, n, u, "out", t] for c_out in commodity(), n in node() if [c_out,n,u,"out"] in generate_CommoditiesNodesUnits())
#         ==
#         + p_FixRatioOutputInputFlow(u,c_out,c_in)
#             * sum(flow[c_in,n, u, "in", t] for c_in in commodity(), n in node() if [c_in,n,u,"in"] in generate_CommoditiesNodesUnits())
#     )
# end

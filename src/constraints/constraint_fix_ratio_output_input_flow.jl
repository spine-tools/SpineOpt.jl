# TODO: check if the constraint does what we want
# NOTE: This function does not return a value
function constraint_fix_ratio_output_input_flow(m::Model, v_flow)
    @constraint(
        m,
        [
            u in unit(),
            cg_out in commoditygroup(),
            cg_in in commoditygroup(),
            t=1:number_of_timesteps(time="timer");
            p_fix_ratio_output_input_flow(unit = u,commoditygroup1 = cg_out,commoditygroup2 = cg_in) != nothing
        ],
        + sum(v_flow[c_out, n, u, "out", t] for c_out in commoditygroup__commodity(commoditygroup = cg_out), n in node()
            if [c_out, n, u] in commodity__node__unit__direction(direction = "out"))

        ==
        + p_fix_ratio_output_input_flow(unit = u, commoditygroup1 = cg_out, commoditygroup2 = cg_in)
            * sum(v_flow[c_in, n, u, "in", t] for c_in in commoditygroup__commodity(commoditygroup = cg_in), n in node()
                if [c_in, n, u] in commodity__node__unit__direction(direction = "in"))
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

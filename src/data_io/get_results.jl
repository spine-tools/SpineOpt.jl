# function create_var_table(m, n, flow, trans, commod="Electricity", unit_con="NodeUnitConnection",
#     node_con="NodeConnectionRelationship", con_con="NodeConnectionRelationship",
#     output_com="output_com", input_com="input_com")
#
#     ucs=Symbol(unit_con)
#     ncs=Symbol(node_con)
#     ccs=Symbol(con_con)
#     ocs=Symbol(output_com)
#     ics=Symbol(input_com)
#
#
#     ## function for reading some results
#     us=eval(ucs)(n)
#     ns=eval(ncs)(n)
#
#     attr_name=[]
#     attr_access_funcs=[]
#     f_iter = 0
#     index=[]
#
#     # function create_conviencience_access_function(f_name,flow, commod,n,u,in_out=nothing,)
#     #     # t=parse("""function $f_name(t);return getvalue($var_name["$c", "$n", "$u", "$in_out", t]); end""")
#     #     @eval begin
#     #         function $(Symbol(f_name))(t)
#     #             return getvalue(flow["$(commod)", "$n", "$u", "$in_out", t])
#     #         end
#     #     end
#     #     return f_name
#     # end
#
#     ##getting relevant units with its connected nodes
#     for u in us
#         if eval(ocs)(u) == [commod] #unit output is connected to node
#             flow_name = "flow_{"*commod*","*n*","*u*","*"out}"
#             push!(attr_name,flow_name)
#             # push!(attr_access_funcs,create_conviencience_access_function("f"*String(f_iter),flow,commod,n,u,"out"))
#             push!(index, ["flow",commod, n, u, "out"])
#         elseif eval(ics)(u) == [commod] #unit input is connected to node
#             flow_name = "flow_{"*commod*","*n*","*u*","*"in}"
#             push!(attr_name,flow_name)
#             # push!(attr_access_funcs,create_conviencience_access_function("f"*String(f_iter),flow,commod,n,u,"in"))
#             push!(index, ["flow",commod, n, u, "in"])
#         end
#     end
#     ##getting relevant connections and their nodes
#     for con in ns
#         n1=eval(ncs)(con)[1]
#         n2=eval(ncs)(con)[2]
#         trans_name1 = "trans_{"*con*","*n1*","*n2*"}"
#         trans_name2 = "trans_{"*con*","*n2*","*n1*"}"
#
#         push!(attr_name,trans_name1)
#         push!(attr_name,trans_name2)
#         # push!(attr_access_funcs,create_conviencience_access_function("f"*String(f_iter),flow,commod,n,u,"in"))
#         push!(index, ["trans",con, n1, n2])
#         push!(index, ["trans",con, n2, n1])
#     end
#     print(index)
#
#     # number_of_timesteps=jfo["number_of_timesteps"]["timer"]
#     # row_names=["flow", "trans", "node1", "node2", "time"]
#     # flow_=[]
#     # trans_=[]
#     # node1=[]
#     # node2=[]
#     # time_=[]
#     # n1 = "LeuvenElectricity"
#     #     df = DataFrame(flow = Float[],trans = Float[], time = Int[], node1=String[], node2=String[])
#     #     for n2 in node()
#     #         for t = 1:number_of_timesteps
#     #
#     #         end
#     #     end
#     t=parse("""getvalue($(index[5][1])["$(index[5][2])","$(index[5][3])","$(index[5][4])",1])""")
#     eval(t)
#     for s in index
#         eval(getvalue(:(trans["ElectricityLine2", "BrusselsElectricity", "LeuvenElectricity",1])))
#     end
#
# end

using DataFrames

function var_to_df(var::JuMP.JuMPArray{JuMP.Variable,5,Tuple{Array{String,1},Array{String,1},Array{String,1},Array{String,1},UnitRange{Int64}}})
    idx = var.indexsets
    df = DataFrame(c=String[], n=String[], u=String[], dire=String[], t=Int32[], val=Float32[])
    # for c in idx[1], n in idx[2], u in idx[3], dire in idx[4], t in idx[5]
    #     push!(df, [c, n, u, dire, t, getvalue(var[c, n, u, dire, t])])
    # end
    return df
end
function var_to_df(var::JuMP.JuMPDict{JuMP.Variable,4})
    df = DataFrame(c=String[], n1=String[], n2=String[], t=Int32[], val=Float32[])
    for (c,n1,n2) in get_all_connection_node_pairs(true), t=1:number_of_timesteps("timer")
        push!(df, [c, n1, n2,t, getvalue(var[c, n1, n2, t])])
    end
    return df
end

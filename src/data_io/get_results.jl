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


function var_to_df(var::JuMP.JuMPDict{JuMP.Variable,5})
    df = DataFrame(c=String[], n=String[], u=String[], dire=String[], t=Int32[], val=Float32[])
    for (c,n,u,dire) in get_com_node_unit_in(), t=1:number_of_timesteps("timer")
        push!(df, [c,n,u,dire,t, getvalue(var[c,n,u,dire,t])])
    end
    return df
end

function var_to_df(var::JuMP.JuMPDict{JuMP.Variable,4})
    df = DataFrame(c=String[], n1=String[], n2=String[], t=Int32[], val=Float32[])
    for (c,n1,n2) in get_all_connection_node_pairs(true), t=1:number_of_timesteps("timer")
        push!(df, [c, n1, n2,t, getvalue(var[c, n1, n2, t])])
    end
    return df
end

# TODO: is this function called from anywhere?
# If yes, we need to add a docstring
"""
Create a data table for one node listing all flows and trans in a dataframe table.
"""
function get_node_streams(n::String, var_flow::JuMP.JuMPDict{JuMP.Variable,5}, var_trans::JuMP.JuMPDict{JuMP.Variable,4}, save=false, output = "opt_results.csv")

    #defining symbols for relationships via stringss
    ncos=Symbol("CommodityAffiliation")
#
    #getting commodity for specific node
    commod=eval(ncos)(n)[1]
#
    ##getting dataframes of flow and trans JuMP variables
    df_flow=var_to_df(var_flow)
    df_trans=var_to_df(var_trans)
#
    ##get relevant connections for node n
    n_flow_con=[]
    for c in get_com_node_unit_in()
        c[2]==n?push!(n_flow_con,c):nothing
    end
    n_trans_con=[]
    for c in get_all_connection_node_pairs(true)
        (c[2]==n)|(c[3]==n)?push!(n_trans_con,c):nothing
    end
    df_list=[]
    column_names=[]
    for c in n_trans_con
        push!(df_list,df_trans[(df_trans[:c] .== c[1]) .& (df_trans[:n1] .== c[2]) .& (df_trans[:n2].==c[3]),:])
        push!(column_names,"trans_"*c[1]*"_"*c[2]*"_"*c[3])
    end
    df_flow_list=[]
    for c in n_flow_con
        push!(df_list,df_flow[(df_flow[:c] .== c[1]) .& (df_flow[:n] .== c[2]) .& (df_flow[:u].==c[3]) .& (df_flow[:dire].==c[4]),:])
        push!(column_names,"flow_"*c[1]*"_"*c[2]*"_"*c[3]*"_"*c[4])
    end

    ##create common data frome for flow and trans
    common_df = DataFrame()
    common_df[:t]=df_list[1][:t]
    for i = 1:length(df_list)
        temp_df = DataFrame()
        temp_df[:t] = df_list[1][:t]
        temp_df[Symbol(column_names[i])] = df_list[i][:val]
        common_df=join(common_df,temp_df, on = :t)
    end

    ##save file
    if save
        CSV.write(output, common_df)
    end

    return common_df
end

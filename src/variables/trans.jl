function trans(m::Model,number_of_timesteps)
    # for c in connection()
    #     for n in node()
    #         for k in node()
    #             if [c,n,k] in get_all_connection_node_pairs(jfo,true)
    # # for connection(),node(),node() in get_all_connection_node_pairs(jfo, true)
    #             @variable(m, trans[c,n,k, t=1:24])
    #
    #         end
    #         end
    #     end
    # end
                    # @variable(m, trans[get_all_connection_node_pairs(jfo,true),t=1:number_of_timesteps])
    @variable(m, trans[c in connection(), i in node(),j in node(), t=1:number_of_timesteps; [c,i,j] in get_all_connection_node_pairs(true)]
)
end

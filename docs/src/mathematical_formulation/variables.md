# Variables 
| Variable name  | Description |  
| :--------------------| :------------------- | 
| ``v_{connection\_flow }(conn, n, d, s, t)`` | Commodity flow associated with node ``n`` over the connection ``conn`` in the direction ``d`` for the stochastic scenario ``s`` at timestep ``t`` | 
| ``v_{connection\_intact\_flow}(conn, n, d, s, t)`` | ??? | 
| ``v_{connections\_decommissioned}(conn, s, t)`` | Number of decomissioned connections ``conn`` for the stochastic scenario ``s`` at timestep ``t`` | 
| ``v_{connections\_invested}(conn, s, t)`` | Number of connections ``conn`` invested at timestep ``t`` in for the stochastic scenario ``s`` | 
| ``v_{connections\_invested\_available}(conn, s, t)`` | Number of invested connections ``conn``  that are available still the stochastic scenario ``s`` at timestep ``t`` | 
| ``v_{mp\_objective\_lowerbound\_indices}(t)`` | Updating lowerbound for master problem of Benders decomposition | 
| ``v_{node\_injection}(n, s, t)`` | Commodity injections at node ``n`` for the stochastic scenario ``s`` at timestep ``t`` | 
| ``v_{node\_slack\_neg}(n, s, t)`` | Positive slack variable at node ``n`` for the stochastic scenario ``s`` at timestep ``t`` | 
| ``v_{node\_slack\_pos}(n, s, t)`` | Negative slack variable at node ``n`` for the stochastic scenario ``s`` at timestep ``t`` | 
| ``v_{node\_state}(n, s, t)`` | Storage state at node ``n`` for the stochastic scenario ``s`` at timestep ``t`` | 
| ``v_{nonspin\_ramp\_down\_unit\_flow}(u, n, d, s, t)`` | Non-spinning down ward reserve commodity flows of unit ``u`` at node ``n``  in the direction ``d`` for the stochastic scenario ``s`` at timestep ``t`` | 
| ``v_{nonspin\_ramp\_up\_unit\_flow}(u, n, d, s, t)`` | Non-spinning upward reserve commodity flows of unit ``u`` at node ``n``  in the direction ``d`` for the stochastic scenario ``s`` at timestep ``t`` | 
| ``v_{nonspin\_units\_shut\_down}(u, n, s, t)`` | Number of units ``u`` held available for non-spinning downward reserve provision via shutdown to node ``n``  for the stochastic scenario ``s`` at timestep ``t`` | 
| ``v_{nonspin\_units\_started\_up}(u, n, s, t)`` | Number of units ``u`` held available for non-spinning upward reserve provision via startup to node ``n``  for the stochastic scenario ``s`` at timestep ``t`` | 
| ``v_{ramp\_down\_unit\_flow}(u, n, d, s, t)`` | Spinning downward ramp commodity flow associated with node ``n`` of unit ``u``  with node ``n`` over the connection ``conn`` in the direction ``d`` for the stochastic scenario ``s`` at timestep ``t`` | 
| ``v_{ramp\_up\_unit\_flow}(u, n, d, s, t)`` | Spinning upward ramp commodity flow associated with node ``n`` of unit ``u``  with node ``n`` over the connection ``conn`` in the direction ``d`` for the stochastic scenario ``s`` at timestep ``t`` | 
| ``v_{shut\_down\_unit\_flow}(u, n, d, s, t)`` | Downward ramp commodity flow during shutdown associated with node ``n`` of unit ``u``  with node ``n`` over the connection ``conn`` in the direction ``d`` for the stochastic scenario ``s`` at timestep ``t`` | 
| ``v_{start\_up\_unit\_flow}(u, n, d, s, t)`` | Upward ramp commodity flow during start-up associated with node ``n`` of unit ``u``  with node ``n`` over the connection ``conn`` in the direction ``d`` for the stochastic scenario ``s`` at timestep ``t`` | 
| ``v_{storages\_decommissioned}(n, s, t)`` | Number of decomissioned storage nodes ``n`` for the stochastic scenario ``s`` at timestep ``t`` | 
| ``v_{storages\_invested}(n, s, t)`` | Number of storage nodes `` n`` invested in  at timestep ``t`` for the stochastic scenario ``s`` | 
| ``v_{storages\_invested\_available}(n, s, t)`` | Number of invested storage nodes ``n``  that are available still the stochastic scenario ``s`` at timestep ``t`` | 
| ``v_{unit\_flow}(u, n, d, s, t)`` | Commodity flow associated with node ``n`` over the unit ``u`` in the direction ``d`` for the stochastic scenario ``s`` at timestep ``t`` | 
| ``v_{unit\_flow\_op}(u, n, d, i, s, t)`` | Contribution of the unit flow assocaited with operating point i | 
| ``v_{units\_available}(u, s, t)`` | Number of available units ``u`` for the stochastic scenario ``s`` at timestep ``t`` | 
| ``v_{units\_invested}(u, s, t)`` | Number of units ``u`` for the stochastic scenario ``s``  invested in at timestep ``t`` | 
| ``v_{units\_invested\_available}(u, s, t)`` | Number of invested units ``u``  that are available still the stochastic scenario ``s`` at timestep ``t`` | 
| ``v_{units\_mothballed}(u, s, t)`` | Number of units ``u`` for the stochastic scenariocenario ``s``  mothballed at timestep ``t`` | 
| ``v_{units\_on}(u, s, t)`` | Number of online units ``u`` for the stochastic scenario ``s`` at timestep ``t`` | 
| ``v_{units\_shut\_down}(u, s, t)`` | Number of units ``u`` for the stochastic scenario ``s`` that switched to offline status at timestep ``t`` | 
| ``v_{units\_started\_up}(u, s, t)`` | Number of units ``u`` for the stochastic scenario ``s`` that switched to online status at timestep ``t`` | 

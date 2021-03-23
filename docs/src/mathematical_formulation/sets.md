# Sets 
| Name | Description | 
| :--------------------| :------------------- | 
| ``(conn, n, d, s, t) \in connection\_flow\_indices`` | Indices of the variable(s) ``v_{connection\_flow }(conn, n, d, s, t)`` | 
| ``(conn, n, d, s, t) \in connection\_intact\_flow\_indices`` | Indices of the variable(s) ``v_{connection\_intact\_flow}(conn, n, d, s, t)`` | 
| ``(conn, s, t) \in connections\_invested\_available\_indices`` | Indices of the variable(s) ``v_{connections\_decommissioned}(conn, s, t)``,``v_{connections\_invested}(conn, s, t)``,``v_{connections\_invested\_available}(conn, s, t)`` | 
| ``t \in mp\_objective\_lowerbound\_indices`` | Indices of the variable(s) ``v_{mp\_objective\_lowerbound\_indices}(t)`` | 
| ``(n, s, t) \in node\_injection\_indices`` | Indices of the variable(s) ``v_{node\_injection}(n, s, t)`` | 
| ``(n, s, t) \in node\_slack\_indices`` | Indices of the variable(s) ``v_{node\_slack\_neg}(n, s, t)``,``v_{node\_slack\_pos}(n, s, t)`` | 
| ``(n, s, t) \in node\_state\_indices`` | Indices of the variable(s) ``v_{node\_state}(n, s, t)`` | 
| ``(u, n, d, s, t) \in nonspin\_ramp\_down\_unit\_flow\_indices`` | Indices of the variable(s) ``v_{nonspin\_ramp\_down\_unit\_flow}(u, n, d, s, t)`` | 
| ``(u, n, d, s, t) \in nonspin\_ramp\_up\_unit\_flow\_indices`` | Indices of the variable(s) ``v_{nonspin\_ramp\_up\_unit\_flow}(u, n, d, s, t)`` | 
| ``(u, n, s, t) \in nonspin\_units\_shut\_down\_indices`` | Indices of the variable(s) ``v_{nonspin\_units\_shut\_down}(u, n, s, t)`` | 
| ``(u, n, s, t) \in nonspin\_units\_started\_up\_indices`` | Indices of the variable(s) ``v_{nonspin\_units\_started\_up}(u, n, s, t)`` | 
| ``(u, n, d, s, t) \in ramp\_down\_unit\_flow\_indices`` | Indices of the variable(s) ``v_{ramp\_down\_unit\_flow}(u, n, d, s, t)`` | 
| ``(u, n, d, s, t) \in ramp\_up\_unit\_flow\_indices`` | Indices of the variable(s) ``v_{ramp\_up\_unit\_flow}(u, n, d, s, t)`` | 
| ``(u, n, d, s, t) \in shut\_down\_unit\_flow\_indices`` | Indices of the variable(s) ``v_{shut\_down\_unit\_flow}(u, n, d, s, t)`` | 
| ``(u, n, d, s, t) \in start\_up\_unit\_flow\_indices`` | Indices of the variable(s) ``v_{start\_up\_unit\_flow}(u, n, d, s, t)`` | 
| ``(n, s, t) \in storages\_invested\_available\_indices`` | Indices of the variable(s) ``v_{storages\_decommissioned}(n, s, t)``,``v_{storages\_invested}(n, s, t)``,``v_{storages\_invested\_available}(n, s, t)`` | 
| ``(u, n, d, s, t) \in unit\_flow\_indices`` | Indices of the variable(s) ``v_{unit\_flow}(u, n, d, s, t)`` | 
| ``(u, n, d, i, s, t) \in unit\_flow\_op\_indices`` | Indices of the variable(s) ``v_{unit\_flow\_op}(u, n, d, i, s, t)`` | 
| ``(u, s, t) \in units\_on\_indices`` | Indices of the variable(s) ``v_{units\_available}(u, s, t)``,``v_{units\_on}(u, s, t)``,``v_{units\_shut\_down}(u, s, t)``,``v_{units\_started\_up}(u, s, t)`` | 
| ``(u, s, t) \in units\_invested\_available\_indices`` | Indices of the variable(s) ``v_{units\_invested}(u, s, t)``,``v_{units\_invested\_available}(u, s, t)``,``v_{units\_mothballed}(u, s, t)`` | 
| ``(u, s, t) \in units\_on\_indices`` | Indices of the variable(s) ``v_{units\_available}(u, s, t)``,``v_{units\_on}(u, s, t)``,``v_{units\_shut\_down}(u, s, t)``,``v_{units\_started\_up}(u, s, t)`` | 
| ``.. \in ind(*parameter*)`` | Tuple of all objects, for which the parameter is defined | 
| ``t \in t\_before\_t(t\_after=t')`` | Set of timeslices that are directly before timeslice t'. | 
| ``t \in t\_before\_t(t\_before=t')`` | Set of timeslices that are directly after timeslice t'. | 
| ``t \in t\_in\_t(t\_short=t')`` | Set of timeslices that contain timeslice t' | 
| ``t \in t\_in\_t(t\_long=t')`` | Set of timeslices that are contained in timeslice t' | 
| ``t \in t\_overlaps\_t(t')`` | Set of timeslices that overlap with timeslice t' | 
| ``[s\_path] \in full\_stochastic\_paths`` | Set of all possible scenario branches | 
| ``[s\_path] \in active\_stochastic\_paths(s)`` | Set of all active scenario branches, based on active scenarios s | 

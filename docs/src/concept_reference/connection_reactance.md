The per-unit series reactance of a transmission line. Used in three ways: 

- ptdf based DC load flow where the relative reactances of lines determine the ptdfs of the network 
- in lossless DC powerflow where the flow on a line is given by `flow = 1/x(theta_to-theta_from)` where x is the reactance of the line, theta_to is the voltage angle of the remote node and theta_from is the voltage angle of the sending node. 
- in AC optimal power flow it describes the series reactance of the line
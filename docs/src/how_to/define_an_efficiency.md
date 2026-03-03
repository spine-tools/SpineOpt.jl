# How to define an efficiency

## relationships between the inputs and outputs of a unit

The image below shows an overview of the possible relationships between the inputs and outputs of a unit.

![image](../figs/definingconversionsforunits.png)

![image](../figs/definingconversionsforunits_legend.png)

The key capability requirements are:
 - Easily define arbitrary numbers of input and output flows
 - Easily create piecewise affine linear relationships between any two flows
 - Anything more complicated can be done via user_constraints

## unit\_\_node\_\_node relationship

![image](../figs/unit__node__node.png)

The `constraint_equality_flow_ratio` parameter of the `unit_flow__unit_flow` relationship class allows you to constrain two `unit_flow` relationships to each other. Ordering of the `unit_flow` entities in the `unit_flow__unit_flow` relationship matters: 
- `node__to_unit` ǀ `unit__to_node`: equivalent to an (incremental) heat rate when the unit is the same in both. Input\_flow = `constraint_equality_flow_ratio` * output\_flow + `constraint_equality_online_coefficient` * `units_on`.  It can be piecewise linear, used in conjunction with `operating_points` with monotonically increasing coefficients (not enforced). Used in conjunction with `constraint_equality_online_coefficient` triggers a fixed flow when the unit is online and `unit_start_flow` triggers a flow on a unit start (start fuel consumption).
- `unit__to_node` ǀ `node__to_unit`: equivalent to an efficiency when the unit is the same in both. Output\_flow = `constraint_equality_flow_ratio` * input\_flow + `constraint_equality_online_coefficient` * `units_on`.  A units\_on coefficient is added with `constraint_equality_online_coefficient`.
- In addition to `node__to_unit` ǀ `unit__to_node` and `unit__to_node` ǀ `node__to_unit` relationships, you can also define the `constraint_equality_flow_ratio` parameter for `node__to_unit` ǀ `node__to_unit` and `unit__to_node` ǀ `unit__to_node` relationships.
- Furthermore, you can have `constraint_less_than_flow_ratio` and `constraint_greater_than_flow_ratio` for any two `unit_flow` entities. For example: `constraint_less_than_flow_ratio` for `node__to_unit` ǀ `unit__to_node` creates the following constraint:
`input_flow` < `constraint_less_than_flow_ratio` * `output_flow` + `constraint_less_than_online_coefficient` * `units_on`

## real world example: Compressed Air Energy Storage

To give a feeling for why these functionalities are useful, consider the following real world example for Compressed Air Energy Storage:

![image](../figs/definingconversionsforunits_realworldexample.png)

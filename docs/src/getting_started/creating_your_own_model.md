# Creating Your Own Model

This part of the guide shows first an example how to insert objects and their parameter data. Then it shows what other objects, relationships and parameter data needs to be added for a very basic model. Lastly, the model instance is run.

## Creating a SpineOpt model instance
- First, open the database editor by double-clicking the *Input DB*. 
- Right click on *model* in the *Object tree*. 
- Choose *Add objects*. 
- Then, add a model object by writing a name to the *object name* field. You can use e.g. *instance*. 
- Click ok.
- The [model](@ref) object in SpineOpt is an abstraction that represents the model itself. Every SpineOpt database needs to have at least one `model` object.
- The model object holds general information about the optimization. The whole range of functionalities is explained in **Advanced Concepts** chapter - in here a minimal set of parameters is used.

![image](https://user-images.githubusercontent.com/40472544/114978841-880e8980-9e92-11eb-9272-5dc46708006f.png)

![image](https://user-images.githubusercontent.com/40472544/114978964-ba1feb80-9e92-11eb-9f73-14a6c11ad3bd.png)

## Add parameter values to the model instance
- Select the model object `instance` from the object tree.
- Go to the `Object parameter value` tab.
- Every parameter value belongs to a specific alternative. This allows to hold multiple values for the same parameter of a particular object. The alternative values are used to create scenarios. Choose, `Base` for all parameter values (`Base` is required in Spine Toolbox - all other alternatives can be chosen freely).
- Then define a `model_start` time and a `model_end` time. 
    - Double-click on the empty row under `parameter_name` and select [model\_start](@ref). 
    - A `None` should appear in `value` column. 
    - To asign a start date value, right-click on `None` and open the editor (cannot be entered directly, since the datatype needs to be changed). 
    - The parameter type of `model_start` is of type `Datetime`. 
    - Set the value to e.g. `2019-01-01T00:00:00`. 
    - Proceed accordingly for the [model\_end](@ref).  

![image](https://user-images.githubusercontent.com/40472544/115030082-5cf65b00-9ecf-11eb-84c3-9dc1c03d4627.png) 

Further reading on adding parameter values can be found [here](https://spine-toolbox.readthedocs.io/en/latest/spine_db_editor/adding_data.html).

## Add other necessary objects and parameter data for the objects. 
- Add all objects and their parameter data by replicating what has been done in the picture below. Do it the same way as explained above with the following caveats.
- Whilst most object names can be freely defined by the user, there is one object name in the example below that needs to be written exactly since it is used internally by SpineOpt: `unit_flow`. 
- The `parameter_name` can be selected from a drop down menu.
- The date time and time series parameter data can be added by using right-click to access the *Edit...* dialog. When creating the time series, use the fixed resolution with `Start time` of the model run and with `1h` resolution. Then only values need to be entered (or copy pasted) and time stamps come automatically.
- Parameter `balance_type` needs to have value `balance_type_none` in the gas node, since it allows the node to create energy (natural gas) against a price and therefore the energy balance is not maintained.

![image](https://user-images.githubusercontent.com/40472544/115030258-8f07bd00-9ecf-11eb-80aa-a717ba5df2f0.png)

## Define temporal and stochastic structures
- To specify the temporal structure for SpineOpt, you need to define [temporal\_block](@ref) objects. Think of a `temporal_block` as a distinctive way of 'slicing' time across the model horizon.
- To link the temporal structure to the spatial structure, you need to specify [node\_\_temporal\_block](@ref) relationships, establishing which `temporal__block` applies to each `node`. This relationship is added by right-clicking the `node__temporal_block` in the relationship tree and then using the `add relationships...` dialog. Double clicking on an empty cell gives you the list of valid objects. The relationship name is automatically formed, but you can change it if that is desirable.
- To keep things simple at this point, let's just define one `temporal_block` for our model and apply it to all `nodes`. We add the object `hourly_temporal_block` of type `temporal_block` following the same procedure as before and establish `node__temporal_block` relationships between `node_gas` and `hourly_temporal_block`, and `electricity_node` and `hourly_temporal_block`.
- In practical terms, the above means that there energy flows over `gas_node` and `electricity_node` for each 'time-slice' comprised in `hourly_temporal_block`.
- Similarly with the stochastic structure, each node is assigned a `deterministic` `stochastic_structure`. 

## Define the spatial structure
- To specify the spatial structure for SpineOpt, you will need to use the [node](@ref), [unit](@ref), and [connection](@ref) objects added before.
- Nodes can be understood as spatial aggregators. In combination with units and connections, they form the energy network.
- Units in SpineOpt represent any kind of conversion process. As one example, a unit can represent a power plant that converts the flow of a commodity fuel into an electricity and/or heat flow.
- Connections on the other hand describe the transport of goods from one location to another. Electricity lines and gas pipelines are examples of such connections. This example does not use connections.
- The database should have an object `gas_turbine` for the `unit` object class and objects `node_gas` and `node_elec` for the `node` object class.
- Next, define how the `unit` and the `nodes` interact with each other: create a [unit\_\_from\_node](@ref) relationship between `gas_turbine` and `node_gas`, and [unit\_\_to\_node](@ref) relationships between `gas_turbine` and `node_elec`.
- In practical terms, the above means that there is an energy flow going from `node_gas` into `node_elec`, through the `gas_turbine`.


## Add remaining relationships and parameter data for the relationships. 
- Similar to adding the objects and their parameter data, add the relationships and their parameter data based on the picture below. 
- The capacity of the gas_turbine has to be sufficient to meet the highest demand for electricity, otherwise the model will be infeasible (it is possible to set penalty values, but they are not included in this example).
- The parameter `fix_ratio_in_out_unit_flow` forces the ratio between an input and output flow to be a constant. This is one way to establish an efficiency for a conversion process.

![image](https://user-images.githubusercontent.com/40472544/115033768-79949200-9ed3-11eb-90e7-e35e6f135a24.png)

## Run the model
- Select *SpineOpt* 
- Press *Execute selection*.

![image](https://user-images.githubusercontent.com/40472544/115010605-48599900-9eb6-11eb-930d-b2a258b61bf7.png)

## If it fails
- Double-check that the data is correct
- Try to see what the problem might be
- Ask help from the [discussion forum](https://github.com/Spine-project/SpineOpt.jl/discussions)

## Explore the results 
- Double-clicking the *Results* database.

![image](https://user-images.githubusercontent.com/40472544/115010687-5d362c80-9eb6-11eb-8542-93a765c186cf.png) 

## Create and run scenarios and build the model further
- Create a new alternative
- Add parameter data for the new alternative
- Connect alternatives under a scenario. Toolbox modifies `Base` data with the data from the alternatives in the same scenario.
- Execute multiple scenarios in parallel. First run in a new Julia instance will need to compile SpineOpt taking some time.

![image](https://user-images.githubusercontent.com/40472544/116697868-618d3a00-a9cc-11eb-9a4c-42f01a4309c5.png)

![image](https://user-images.githubusercontent.com/40472544/115011214-0da43080-9eb7-11eb-93e5-e2991e81b429.png)

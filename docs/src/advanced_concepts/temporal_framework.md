# Temporal Framework

Spine Model aims to provide a high degree of flexibility in the temporal dimension across different components of the created model. This means that the user has some freedom to choose how the temporal aspects of different components of the model are defined. This freedom increases the variety of problems that can be tackled in Spine: from very coarse, long term models, to very detailed models with a more limited horizon, or a mix of both. The choice of the user on how this flexibility is used will lead to the temporal structure of the model.

The main components of flexibility consist of the following parts:
  * The horizon that is modeled: end and start time
  * Temporal resolution
  * Possibility of a rolling optimization window
  * Support for commonly used methods such as representative days

Part of the temporal flexibility in Spine is due to the fact that these options mentioned above can be implemented differently across different components of the model, which can be very useful when different markets are coupled in a single model. The resolution and horizon of the gas market can for example be taken differently than that of the electricity market. This documentation aims to give the reader insight in how these aspects are defined, and which objects are used for this.

We start by introducing the relevant objects with their parameters, and the relevant relationship classes for the temporal structure. Afterwards, we will discuss how this setting creates flexibility and will present some of the practical approaches to create a variety of temporal structures.

## Objects, relationships, and their parameters
In this section, the objects and relationships will be discussed that form the temporal structure together.
### Objects relevant for the temporal framework
For the objects, the relevant parameters will also be introduced, along with the type of values that are allowed, following the format below:  

* 'parameter_name' : "Allowed value type"

#### [model](@ref) object
Each `model` object holds general information about the model at hand. Here we only discuss the time related parameters:
* [model_start](@ref) and [model_end](@ref) : "Date time value"
These two parameters define the model horizon. A Datetime value is to be taken for both parameters, in which case they directly mark respectively the beginning and end of the modeled time horizon.

* [duration_unit](@ref) (optional): "minute or hour"
 This parameters gives the unit of duration that is used in the model calculations. The default value for this parameter is 'minute'.
 E.g. if the [duration\_unit](@ref) is set to `hour`, a `Duration` of one `minute` gets converted into `1/60 hours` for the calculations.

* [roll_forward](@ref) (optional): "duration value"
This parameter defines how much the optimization window rolls forward in a rolling horizon optimization and should be expressed as a duration. In the practical approaches presented below, the rolling window optimization will be explained in more detail.


#### [temporal_block](@ref)  object
A temporal block defines the properties of the optimization that is to be solved in the current window. Most importantly, it holds the necessary information about the resolution and horizon of the optimization.

* [resolution](@ref) (optional): "duration value" or "array of duration values"

This parameter specifies the resolution of the temporal block, or in other words: the length of the timesteps used in the optimization run.

* [block_start](@ref) (optional): "duration value" or "Date time value"
Indicates the start of this temporal block.

* [block_end](@ref)(optional): "duration value" or "Date time value"
Indicates the end of this temporal block.


### Relationships relevant for the temporal framework

#### [model\_\_temporal\_block](@ref) relationship
In this relationship, a model instance is linked to a temporal block. If this relationship doesn't exist - the temporal block is disregarded from this optimization model.
#### [model\_\_default\_temporal\_block](@ref) relationship
Defines the default temporal block used for model objects, which will be replaced when a specific relationship is defined for a model in `model__temporal_block`.
#### [node\_\_temporal\_block](@ref) relationship
This relationship will link a node to a temporal block.

#### [units\_on\_\_temporal_block](@ref) relationship
This relationship links the `units_on` variable of a unit to a temporal block and will therefore govern the time-resolution of the unit's online/offline status.
#### [unit\__investment\_temporal_block](@ref) relationship
This relationship sets the temporal dimensions for investment decisions of a certain unit. The separation between this relationship and the `units_on__temporal_block`, allows the user for example to give a much finer resolution to a unit's on- or offline status than to it's investment decisions.
#### [model\_\_default\_investment\_temporal\_block](@ref) relationship
Defines the default temporal block used for investment decisions, which will be replaced when a specific relationship is defined for a unit in `unit__investment_temporal_block`.
## General principle of the temporal framework

The general principle of the Spine modeling temporal structure is that different temporal blocks can be defined and linked to different objects in a model. This leads to great flexibility in the temporal structure of the model as a whole. To illustrate this, we will discuss some of the possibilities that arise in this framework.

### One single `temporal_block`

#### Single solve with single block
The simplest case is a single solve of the entire time horizon (so `roll_forward` not defined) with a fixed resolution. In this case, only one temporal block has to be defined with a fixed resolution. Each node has to be linked to this `temporal_block`.

Alternatively, a variable resolution can be defined by choosing an array of durations for the [resolution](@ref) parameter. The sum of the durations in the array then have to match the length of the temporal block. The example below illustrates an optimization that spans one day for which the resolution is hourly in the beginning and then gradually decreases to a 6h resolution at the end.

* `temporal_block_1`
  * `block_start`: 0h *(Alternative `DateTime`: e.g. 2030-01-01T00:00:00)*
  * `block_end`: 1D *(Alternative `DateTime`: e.g. 2030-01-02T00:00:00)*
  * `resolution`: [1h 1h 1h 1h 2h 2h 2h 4h 4h 6h]

Note that, as mentioned above, the [block\_start](@ref) and [block\_end](@ref) parameters can also be entered as absolute values, i.e. `DateTime` values.

#### Rolling window optimization with single block
A model with a single `temporal_block` can also be optimized in a rolling horizon framework. In this case, the `roll_forward` parameter has to be defined in the `model` object. The `roll_forward` parameter will then determine how much the optimization moves forward with every step, while the size of the temporal block will determine how large a time frame is optimized in each step. To see this more clearly, let's take a look at an example.

Suppose we want to model a horizon of one week, with a rolling window size of one day. The `roll_forward` parameter will then be a duration value of 1d. If we take the `temporal_block` parameters `block_start` and `block_end` to be the duration values 0h and 1d respectively, the model will optimize each day of the week separately. However, we could also take the `block_end` parameter to be 2d. Now the model will start by optimizing day 1 and day 2 together, after which it keeps only the values obtained for the first day, and moves forward to optimize the second and third day together.

Again, a variable resolution can be implemented for the rolling window optimization. The sum of the durations must in this case match the size of the optimized window.

### Advanced usage: multiple `temporal_block` objects

#### Single solve with multiple blocks
##### Disconnected time periods
Multiple temporal blocks can be used to optimize disconnected periods. Let's take a look at an example in which two temporal blocks are defined.

* `temporal_block_1`
  * `block_start`: 0h
  * `block_end`: 4h
* `temporal_block_2`
  * `block_start`: 12h
  * `block_end`: 16h

This example will lead to an optimization of the first four hours of the model horizon, and also of hour 12 to 16. By defining exactly the same relationships for the two temporal blocks, an optimization of disconnected periods is achieved for exactly the same model components. This leads to the possibility of implementing the widely used representative days method. If desired, it is possible to choose a different temporal resolution for the different `temporal_blocks`.

It is worth noting that dynamic [variables](@ref Variables) like [node\_state](@ref) and [units\_on](@ref)
merit special attention when using disconnected time periods.
By default, when trying to access [variables](@ref Variables) Variables outside the defined [temporal\_block](@ref)s,
*SpineOpt.jl* assumes such variables exist but allows them to take any values within specified bounds.
If fixed initial conditions for the disconnected periods are desired,
one needs to use parameters such as [fix\_node\_state](@ref) or [fix\_units\_on](@ref).

##### Different regions/commodities in different resolutions

Multiple temporal blocks can also be used to model different regions or different commodities with a different resolution. This is especially useful when there is a certain region or commodity of interest, while other elements are connected to this but require less detail. For this kind of usage, the relationships that are defined for the temporal blocks will be different, as shown in the example below.

* `temporal_blocks`
  * `temporal_block_1`
    * `resolution`: 1h
  * `temporal_block_2`
    * `resolution`: 2h
* `nodes`
  * `node_1`
  * `node_2`
* `node_temporal_block` relationships
  * `node_1_temporal_block_1`
  * `node_2_temporal_block_2`

Similarly, the on- and offline status of a unit can be modeled with a lower resolution than the actual output of that unit, by defining the `units_on_temporal_block` relationship with a different temporal block than the one used for the `node_temporal_block` relationship (of the node to which the unit is connected).


#### Rolling horizon with multiple blocks
##### Rolling horizon with different window sizes
Similar to what has been discussed above in [Different regions/commodities in different resolutions](@ref), different commodities or regions can be modeled with a different resolution in the rolling horizon setting. The way to do it is completely analogous. Furthermore, when using the rolling horizon framework, a different window size can be chosen for the different modeled components, by simply using a different `block_end` parameter. However, using different [block\_end](@ref)s e.g. for interconnected regions should be treated with care, as the variables for each region will only be generated for their respective [temporal\_block](@ref), which in most cases will lead to inconsistent linking constraints.

##### Putting it all together: rolling horizon with variable resolution that differs for different model components
Below is an example of an advanced use case in which a rolling horizon optimization is used, and different model components are optimized with a different resolution. By choosing the relevant parameters in the following way:
* `model`
  * `roll_forward`: 4h
* `temporal_blocks`
  * `temporal_block_A`
    * `resolution`: [1h 1h 2h 2h 2h 3h 3h]
    * `block_end`: 14h
  * `temporal_block_B`
    * `resolution`: [2h 2h 4h 6h]
    * `block_end`: 14h
* `nodes`
  * `node_1`
  * `node_2`
* `node_temporal_block` relationships
  * `node_1_temporal_block_A`
  * `node_2_temporal_block_B`
The two model components that are considered have a different resolution, and their own resolution is also varying within the optimization window. Note that in this case the two optimization windows have the same size, but this is not strictly necessary. The image below visualizes the first two window optimizations of this model.

![temporal structure](../figs/Temporal_structure.svg)

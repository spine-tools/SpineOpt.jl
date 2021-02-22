# Creating Your Own Model

TODO: Explain the steps necessary top start creating your own models using *SpineOpt* and *Spine Toolbox*.

### Creating a SpineOpt database

Create an empty Spine database e.g. *example.db* by following the [documentation of Spine Toolbox](https://spine-toolbox.readthedocs.io/en/master/data_store_form/getting_started.html).
To make this database a *SpineOpt* database, import the SpineOpt template. This template is located in your local SpineOpt repository `../data/spineopt_template.json` or can alternatively
be downloaded [here](https://github.com/Spine-project/SpineOpt.jl/blob/master/data/spineopt_template.json). To import this template in the empty Spine database, follow the instructions
described here (https://spine-toolbox.readthedocs.io/en/master/data_store_form/importing_and_exporting_data.html).

This will insert a predefined set of object classes, relationship classes,
and parameter definitions required by SpineOpt to run,
as well as sensitive default values for those parameters.

### Defining the model structure

The first step in defining a SpineOpt is to create the objects and relationships
that specify the model structure.


#### Defining the model object

The [model](@ref) object in SpineOpt is an abstraction that represents the model itself.
Every SpineOpt database needs to have at least one `model` object.

One way to add a model object to `example.db` using the `Stacked view` in SpineToolbox is to right-click the `object_class` model and select "Add objects" from the drop-down menu. By adding the object name `quick_start`, we have
now created a new model object. For reference, these steps are described in more detail [here](https://spine-toolbox.readthedocs.io/en/master/data_store_form/adding_data.html#adding-object-classes).

The model object holds general information about the optimization. The whole range of functionalities is later explained in **Advanced Concepts** chapter, but for this example we will
only add the optimization horizon. For this, you need to enter start and end date of the optimization. To do so, select the object `quick_start` and go to the `Object parameter value` tab. Double-click on the empty row under `parameter_name`
and select [model\_start](@ref). A `None` should appear in `value` column. To asign a start date value, right-click on `None` and open the editor. The parameter type of `model_start` is of type `Datetime`. Set the value to e.g. `2021-01-01T00:00:00`. Proceed accordingly
for the [model\_end](@ref). Further reading on adding parameter values can be found [here](https://spine-toolbox.readthedocs.io/en/master/data_store_form/adding_data.html#adding-parameter-values).

TODO: add some illustrative pictures

#### Defining the spatial structure

To specify the spatial structure for SpineOpt, you need to define [commodity](@ref), [node](@ref), [unit](@ref), and [connection](@ref) objects,
together with the relationships that define their interactions.

Commodities are any kind of tradable good. These goods can for instance be electricity, heat, gas, and water.

Nodes provide the locational information of such commodities. They can be understood as spatial aggregators. In combination with units and connections, they
form the energy network.

Units in SpineOpt represent any kind of conversion process. As one example, a unit can represent a power plant the converts the flow of a commodity fuel into an electricity and/or heat flow.

Connections on the other hand describe the transport of goods from one location to another. Electricity lines and gas pipelines are examples of such connections.

Let's add some `units` and `nodes` to our database to start building our model. We proceed by adding the objects `gas_import`, `power_plant` of type `unit` and
`gas_node` and `electricity_node` of type `node`, following the same methodology as before for our object `quick_start` of type `model`.

To specify how these `units` and `nodes` may interact with each other,
let's define a [unit\_\_from\_node](@ref) relationship between `power_plant` and `gas_node`, and [unit\_\_to\_node](@ref) relationships between `gas_import` and `gas_node`, and `power_plant` and `electricity_node`.

Using the `Stacked view` again, we right click the respective relationship classes and select `Add relationships`. The corresponding objects can now be related.
In practical terms, the above means that there are energy flows
going from `gas_import` into `gas_node`, as well as from `gas_node` into `power_plant`,
and from `power_plant` into `electricity_node`.


#### Defining the temporal structure

To specify the temporal structure for SpineOpt, you need to define [temporal\_block](@ref) objects.
Think of a `temporal_block` as a distinctive way of 'slicing' time across the model horizon.

To link the temporal structure to the spatial structure,
you need to specify [node\_\_temporal\_block](@ref) relationships,
establishing which `temporal__block` applies to each `node`.

To keep things simple at this point,
let's just define one `temporal_block` for our model and apply it to all `nodes`. We add the object `hourly_temporal_block` of type `temporal_block`
following the same procedure as before and establish `node__temporal_block` relationships between 
`gas_node` and `hourly_temporal_block`, and `electricity_node` and `hourly_temporal_block`.
In practical terms, the above means that there energy flows over `gas_node` and `electricity_node`
for each 'time-slice' comprised in `hourly_temporal_block`.

To ensure that a `temporal_block` belongs to a certain `model`, we must furthermore establish a relationship 
of type [model\_\_temporal_block](@ref) between `hourly_temporal_block` and `quick_start`.

#### Defining the stochastic structure

To specify the stochastic structure for SpineOpt,
you need to define [stochastic\_scenario](@ref) and [stochastic\_structure](@ref) objects,
together with [stochastic\_structure\_\_stochastic\_scenario](@ref) relationships
(and optionally, [parent\_stochastic\_scenario\_\_child\_stochastic\_scenario](@ref) relationships).

To link the stochastic structure to the spatial structure,
you need to define [node\_\_stochastic\_structure](@ref) relationships,
establishing which `stochastic_structure` applies to each `node`.

To keep things simple at this point,
let's just define one `stochastic_structure` for our model with one `stochastic_scenario` ,
and apply it to all `nodes`: We add a `stochastic_structure` object called `deterministic` and define the object `base_case` of type `stochastic_scenario`.

In SpineOpt, every node needs to be connected to exactly *one* object of type `stochastic_structure`. We establish relationships between all nodes to the new object `deterministic`.
To bring the `stochastic_structure` and the `stochastic_scenario` together (defining our scenario tree), we link `deterministic` and `base_case` through a relationship of type 
`stochastic_structure__stochastic_scenario`.

### Specifying the model behavior

The second step in defining a SpineOpt is to specify the object and parameter values
that dictate the model behavior.

TO BE CONTINUED...
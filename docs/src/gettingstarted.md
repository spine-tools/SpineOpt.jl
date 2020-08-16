# Getting started

## Introduction
*[Spineopt]: longer text

This provides the ability to generate and run the Spine energy system integration model
(in short, *SpineOpt*)
from databases having the appropriate structure.
`SpineOpt` uses [`SpineInterface`](https://github.com/Spine-project/SpineInterface.jl)
to gain access to the contents of the database,
and [`JuMP`](https://github.com/JuliaOpt/JuMP.jl) to build and solve
an optimisation model based on those contents.
 **TODO: say something about SpineToolbox**

## Compatibility

This package requires Julia 1.2 or later.

## Prerequisites

**TODO: say something about SpineToolbox, prerequisits**

## Installation

```julia
julia> using Pkg

julia> pkg"registry add https://github.com/Spine-project/SpineJuliaRegistry"

julia> pkg"add SpineOpt"

```


## Quick start guide

Once `SpineOpt` is installed, to use it in your programs you just need to say:

```julia
julia> using SpineOpt
```

To run SpineOpt for a SpineOpt database, say:

```julia
julia> run_spineopt("...url of a SpineOpt database...")
```

In what follows, we demonstrate how to setup a database for a simple example through
[Spine Toolbox](https://github.com/Spine-project/Spine-Toolbox).

### Creating a SpineOpt database

Create an empty Spine database e.g. "example.db"" by following the [documentation of Spine Toolbox](https://spine-toolbox.readthedocs.io/en/master/data_store_form/getting_started.html).
To make this database a Spine*Opt* database, import the SpineOpt template. This template is located in your local SpineOpt repository `../data/spineopt_template.json` or can alternatively
be downloaded [here](https://github.com/Spine-project/SpineOpt.jl/blob/master/data/spineopt_template.json). To import this template in the empty Spine database, follow the instructions
described here (https://spine-toolbox.readthedocs.io/en/master/data_store_form/importing_and_exporting_data.html).

This will insert a predefined set of object classes, relationship classes,
and parameter definitions required by SpineOpt to run,
as well as sensitive default values for those parameters.

### Defining the model structure

The first step in defining a SpineOpt is to create the objects and relationships
that specify the model structure.


#### Defining the model object

The **model** object in SpineOpt is an abstraction that represents the model itself.
Every SpineOpt database needs to have exactly one **model** object.

One way to add a model object to "example.db" using the **Stacked view** in SpineToolbox is to right-click the *object_class* model and select "Add objects" from the drop-down menu. By adding the object name "quick_start", we have
now created a new model object. For reference, these steps are described in more detail [here](https://spine-toolbox.readthedocs.io/en/master/data_store_form/adding_data.html#adding-object-classes).

The model object holds general information about the optimization. The whole range of functionalities is later explained in *ref* *TODO: how to cross-ref?*, but for this example we will
only add the optimization horizon. For this, you need to enter the start data and the end date of the optimization. To do so, select the object "quick_start" and go to the "Object parameter value" tab. Double-click on the empty row under *parameter_name*
and select *model_start*. A *None* should appear in *value* column. To asign a start date value, right-click on *None* and open the editor. The parameter type of *model_start* is of type *Datetime*. Set the value to e.g. 2021-01-01T00:00:00. Proceed accordingly
for the *model_end*. Further reading on adding parameter values can be found [here](https://spine-toolbox.readthedocs.io/en/master/data_store_form/adding_data.html#adding-parameter-values).


#### Defining the spatial structure

To specify the spatial structure for SpineOpt, you need to define **commodity**, **node**, **unit**, and **connection** objects,
together with the relationships that define their interactions.

Commodities are any kind of tradable good. These goods can for instance be electricity, heat, gas, and water.

Nodes provide the locational information of such commodities. They can be understood as spatial aggregators. In combination with units and connections, they
form the energy network.

Units in SpineOpt represent any kind of conversion process. As one example, a unit can represent a power plant the converts the flow of a commodity fuel into an electricity and/or heat flow.

Connections on the other hand describe the transport of goods from one location to another. Electricity lines and gas pipelines are examples of such connections.

Let's add some **units** and **nodes** to our database to start building our model. We proceed by adding the objects "gas_import", "power_plant" of type "unit" and
"gas_node" and "electricity_node" of type "node", following the same methodology as we did above for our object "quick_start" of type "model".

To specify how these **units** and **nodes** may interact with each other,
let's define some **unit__from_node** and **unit__to_node** relationships:

```julia
julia> relationships = [
	["unit__to_node", ["gas_import", "gas_node"]],
	["unit__from_node", ["power_plant", "gas_node"]],
	["unit__to_node", ["power_plant", "electricity_node"]],
];

julia> db_api.import_data_to_url(url; relationships=relationships)

```

In practical terms, the above means that there are energy flows
going from *gas_import* into *gas_node*, as well as from *gas_node* into *power_plant*,
and from *power_plant* into *electricity_node*.


#### Defining the temporal structure

To specify the temporal structure for SpineOpt, you need to define **temporal_block** objects.
Think of a **temporal_block** as a distinctive way of 'slicing' time across the model horizon.

To link the temporal structure to the spatial structure,
you need to specify **node__temporal_block** relationships,
establishing which **temporal__block** applies to each **node**.

To keep things simple at this point,
let's just define one **temporal_block** for our model and apply it to all **nodes**:

```julia
julia> objects = [["temporal_block", "hourly_temporal_block"]];

julia> relationships = [
	["node__temporal_block", ["gas_node", "hourly_temporal_block"]],
	["node__temporal_block", ["electricity_node", "hourly_temporal_block"]]
];

julia> db_api.import_data_to_url(url; objects=objects, relationships=relationships)

```

In practical terms, the above means that there energy flows over *gas_node* and *electricity_node*
for each 'time-slice' comprised in *hourly\_temporal_block*.



#### Defining the stochastic structure

To specify the stochastic structure for SpineOpt,
you need to define **stochastic_scenario** and **stochastic_structure** objects,
together with **stochastic\_structure__stochastic\_scenario** relationships
(and optionally, **parent\_stochastic\_scenario__child\_stochastic\_scenario** relationships).

To link the stochastic structure to the spatial structure,
you need to define **node__stochastic_structure** relationships,
establishing which **stochastic_structure** applies to each **node**.

To keep things simple at this point,
let's just define one **stochastic_structure** for our model with one **stochastic_scenario**,
and apply it to all **nodes**:

```julia
julia> objects = [
	["stochastic_structure", "deterministic"],
	["stochastic_scenario", "base_case"],
];

julia> relationships = [
	["stochastic_structure__stochastic_scenario", ["deterministic", "base_case"]],
	["node__stochastic_structure", ["electricity_node", "deterministic"]]
	["node__stochastic_structure", ["gas_node", "deterministic"]]
];

julia> db_api.import_data_to_url(url; objects=objects, relationships=relationships)

```


### Specifying the model behavior

The second step in defining a SpineOpt is to specify the object and parameter values
that dictate the model behavior.

TO BE CONTINUED...


## Library outline

```@contents
Pages = ["library.md"]
Depth = 5
```

## Qucik start guide

### System components

### Model objects

### Temporal block objects

### Node objects

**Ref to temporal_block stoachtsic strucutre**
** Link to advanced usage storages **

### Unit objects

### Connection objects

## Relationship classes

### Basic model structure

### Examples

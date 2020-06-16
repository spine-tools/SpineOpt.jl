# SpineOpt.jl

This package provides the ability to generate and run the Spine energy system integration model
(in short, *Spine Opt*)
from databases having the appropriate structure.
`SpineOpt` uses [`SpineInterface`](https://github.com/Spine-project/SpineInterface.jl)
to gain access to the contents of the database,
and [`JuMP`](https://github.com/JuliaOpt/JuMP.jl) to build and solve
an optimisation model based on those contents.


## Compatibility

This package requires Julia 1.2 or later.

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

To generate and run Spine Opt for a database, say:

```julia
julia> run_spineopt("...url of a Spine Opt database...")
```

In what follows, we demonstrate how to setup a database for a simple Spine Opt
**using only SpineOpt.jl**.
However, please note that
**the recomended way of creating, populating, and maintaining Spine databases is through 
[Spine Toolbox](https://github.com/Spine-project/Spine-Toolbox).**

### Creating a Spine Opt database

Create a new Spine database by running:

```julia
julia> url = "sqlite:///example.db";

julia> import SpineInterface: db_api  # brings `db_api` into scope

julia> db_api.create_new_spine_database(url);
```

The above will create a SQLite file called `example.db` in the present working directory,
with the Spine database schema in it.

To make it a Spine *Opt* database, run:

```julia
julia> template = Dict(Symbol(key) => value for (key, value) in SpineOpt.template);

julia> db_api.import_data_to_url(url_in; template...)
```

This will insert a predefined set of object classes, relationship classes,
and parameter definitions required by Spine Opt to run,
as well as sensitive default values for those parameters.

### Defining the model structure

The first step in defining a Spine Opt is to create the objects and relationships
that specify the model structure.


#### Defining the model object

The **model** object in Spine Opt is an abstraction that represents the model itself.
Every Spine Opt database needs to have exactly one **model** object.
Let's create one for our database by running:

```julia
julia> db_api.import_data_to_url(url; objects=[["model", "quick_start"]])

```

#### Defining the spatial structure

To specify the spatial structure for Spine Opt, you need to define **node**, **unit**, and **connection** objects,
together with the relationships that define their interactions.
You can think of the **node** as sort-of an 'aggregator',
whereas the **unit** and the **connection** are sort-of 'devices' installed in between **nodes**.

Let's add some **units** and **nodes** to our database to start building our model. Run:

```julia
julia> objects = [
	["unit", "gas_import"],
	["unit", "power_plant"],
	["node", "gas_node"],
	["node", "electricity_node"],
];

julia> db_api.import_data_to_url(url; objects=objects)

```

The above will add to the database two **units** named *gas_import* and *power_plant*,
and two **nodes** named *gas_node* and *electricity_node*.

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

To specify the temporal structure for Spine Opt, you need to define **temporal_block** objects.
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

To specify the stochastic structure for Spine Opt, 
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

The second step in defining a Spine Opt is to specify the object and parameter values
that dictate the model behavior.

TO BE CONTINUED...


## Library outline

```@contents
Pages = ["library.md"]
Depth = 3
```

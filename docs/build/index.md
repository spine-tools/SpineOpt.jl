
<a id='SpineModel.jl-Documentation-1'></a>

# SpineModel.jl Documentation

- [SpineModel.jl Documentation](index.md#SpineModel.jl-Documentation-1)
    - [Functions](index.md#Functions-1)
        - [Data input/output](index.md#Data-input/output-1)
    - [Macros](index.md#Macros-1)
    - [Index](index.md#Index-1)


<a id='Functions-1'></a>

## Functions


<a id='Data-input/output-1'></a>

### Data input/output

<a id='SpineModel.JuMP_all_out' href='#SpineModel.JuMP_all_out'>#</a>
**`SpineModel.JuMP_all_out`** &mdash; *Function*.



```
JuMP_all_out(sdo::SpineDataObject, update_all_datatypes=true)
```

Generate and export convenience functions named after each object class, relationship class, and parameter in `sdo`, providing compact access to its contents. These functions are intended to be called in JuMP programs, as follows:

  * **object class**: call `x()` to get the set of names of objects of the class named `"x"`.
  * **relationship class**: call `y("k")` to get the set of names of objects related to the object named `"k"`, by a relationship of class named `"y"`, or an empty set if no such relationship exists.
  * **parameter**: call `z("k", t)` to get the value of the parameter named `"z"` for the object named `"k"`, or `Nullable()` if the parameter is not defined. If this value is an array in the Spine object, then `z("k", t)` returns position `t` in that array.

If `update_all_datatypes` is `true`, then the method tries to find the julia `Type` that best fits all values for every parameter in `sdo`, and converts all values to that `Type`. (See `SpineData.update_all_datatypes!`.)

**Example**

```julia
julia> JuMP_all_out(sdo)
julia> commodity()
3-element Array{String,1}:
 "coal"
 "gas"
...
julia> unit_node("Leuven")
4-element Array{String,1}:
 "coal_import"
 "gas_fired_power_plant"
...
julia> conversion_cost("gas_import")
12
julia> demand("Leuven", 17)
700
```


<a target='_blank' href='https://gitlab.vtt.fi/spine/model/blob/ff46dedbc561f1497e958095143986eefc03bce5/src/data_io/Spine.jl#L19-57' class='documenter-source'>source</a><br>

<a id='SpineModel.JuMP_all_out' href='#SpineModel.JuMP_all_out'>#</a>
**`SpineModel.JuMP_all_out`** &mdash; *Function*.



```
JuMP_all_out(source, update_all_datatypes=true)
```

Generate and export convenience functions named after each object class, relationship class, and parameter in `source`, providing compact access to its contents, where `source` is anything convertible to a `SpineDataObject` by the `SpineData.jl` package. See also: [`JuMP_all_out(sdo::SpineDataObject, update_all_datatypes=true)`](index.md#SpineModel.JuMP_all_out) for details about the generated convenience functions.

If `update_all_datatypes` is `true`, then the method tries to find out the julia `Type` that best fits all values for every parameter in `sdo`, and converts all values to that `Type`. (See `SpineData.update_all_datatypes!`.)


<a target='_blank' href='https://gitlab.vtt.fi/spine/model/blob/ff46dedbc561f1497e958095143986eefc03bce5/src/data_io/Spine.jl#L1-13' class='documenter-source'>source</a><br>

<a id='SpineModel.JuMP_object' href='#SpineModel.JuMP_object'>#</a>
**`SpineModel.JuMP_object`** &mdash; *Function*.



```
JuMP_object(sdo::SpineDataObject, update_all_datatypes=true)
```

A julia `Dict` providing custom maps of the contents of `sdo`. In what follows, `jfo` designs this `Dict`. The specific roles of these maps are described below:

  * **object class map**: `object_class_name::String` ⟶ `object_names::Array{String,1}`. This map assigns an object class's name to a list of names of objects of that class. You can refer to the set of objects of the class named `"x"` as `jfo["x"]`.
  * **relationship class map**: `relationship_class_name::String` ⟶ `object_name::String` ⟶ `related_object_names::Array{String,1}`. This multilevel map assigns, for each relationship class name, a map from an object's name to a list of related object names. You can use this map to get the set of names of objects related to the object called `"k"` by a relationship of the class named `"y"` as `jfo["y"]["k"]`.
  * **parameter map**: `parameter_name::String` ⟶ `object_name::String` ⟶ `parameter_value::T`. This multilevel map assigns, for each parameter name, a map from an object's name to the value of the parameter for that object. You can use this map to access the value of the parameter called `"z"` for the object called `"k"` as `jfo["z"]["k"]`. If the value for this parameter in `sdo` is an array, you can access position `t` in that array as `jfo["z"]["k"][t]`

**Example**

```julia
julia> jfo = JuMP_object(sdo);
julia> jfo["unit"]
4-element Array{String,1}:
 "coal_import"
 "gas_fired_power_plant"
...
julia> jfo["unit_node"]
Dict{String,String} with 5 entries:
  "coal_fired_power_plant" => ["Leuven"]
  "coal_import"  => ["Leuven"]
  ...
  "Leuven" => ["coal_fired_power_plant", "coal_import", ...]
...
julia> jfo["conversion_cost"]
Dict{String,Int64} with 4 entries:
  "gas_import" => 12
  "coal_fired_power_plant"  => 0
...
```


<a target='_blank' href='https://gitlab.vtt.fi/spine/model/blob/ff46dedbc561f1497e958095143986eefc03bce5/src/data_io/Spine.jl#L103-148' class='documenter-source'>source</a><br>

<a id='SpineData.Spine_object-Tuple{Dict}' href='#SpineData.Spine_object-Tuple{Dict}'>#</a>
**`SpineData.Spine_object`** &mdash; *Method*.



```
SpineData.Spine_object(jfo::Dict)
```

A `SpineDataObject` from `jfo`.

See also [`JuMP_object(sdo::SpineDataObject, update_all_datatypes=true)`](index.md#SpineModel.JuMP_object).


<a target='_blank' href='https://gitlab.vtt.fi/spine/model/blob/ff46dedbc561f1497e958095143986eefc03bce5/src/data_io/Spine.jl#L240-246' class='documenter-source'>source</a><br>


<a id='Macros-1'></a>

## Macros

<a id='SpineModel.@JuMPout-Tuple{Any,Vararg{Any,N} where N}' href='#SpineModel.@JuMPout-Tuple{Any,Vararg{Any,N} where N}'>#</a>
**`SpineModel.@JuMPout`** &mdash; *Macro*.



```
JuMPout(dict, keys...)
```

Create a variable named after each one of `keys`, by taking its value from `dict`.

**Example**

```julia
julia> @JuMPout(jfo, capacity, node);
julia> node == jfo["node"]
true
julia> capacity == jfo["capacity"]
true
```


<a target='_blank' href='https://gitlab.vtt.fi/spine/model/blob/ff46dedbc561f1497e958095143986eefc03bce5/src/data_io/util.jl#L1-14' class='documenter-source'>source</a><br>

<a id='SpineModel.@JuMPout_suffix-Tuple{Any,Any,Vararg{Any,N} where N}' href='#SpineModel.@JuMPout_suffix-Tuple{Any,Any,Vararg{Any,N} where N}'>#</a>
**`SpineModel.@JuMPout_suffix`** &mdash; *Macro*.



```
JuMPout_suffix(dict, suffix, keys...)
```

Like [`@JuMPout(dict, keys...)`](index.md#SpineModel.@JuMPout-Tuple{Any,Vararg{Any,N} where N}) but appending `suffix` to the variable name. Useful when working with several systems at a time.

**Example**

```julia
julia> @JuMPout_suffix(jfo, _new, capacity, node);
julia> capacity_new == jfo["capacity"]
true
julia> node_new == jfo["node"]
true
```


<a target='_blank' href='https://gitlab.vtt.fi/spine/model/blob/ff46dedbc561f1497e958095143986eefc03bce5/src/data_io/util.jl#L21-35' class='documenter-source'>source</a><br>

<a id='SpineModel.@JuMPout_with_backup-Tuple{Any,Any,Vararg{Any,N} where N}' href='#SpineModel.@JuMPout_with_backup-Tuple{Any,Any,Vararg{Any,N} where N}'>#</a>
**`SpineModel.@JuMPout_with_backup`** &mdash; *Macro*.



```
JuMPout_with_backup(dict, backup, keys...)
```

Like [`@JuMPout(dict, keys...)`](index.md#SpineModel.@JuMPout-Tuple{Any,Vararg{Any,N} where N}) but also looking into `backup` if the key is not in `dict`.


<a target='_blank' href='https://gitlab.vtt.fi/spine/model/blob/ff46dedbc561f1497e958095143986eefc03bce5/src/data_io/util.jl#L42-46' class='documenter-source'>source</a><br>

<a id='SpineModel.@JuMPin-Tuple{Any,Vararg{Any,N} where N}' href='#SpineModel.@JuMPin-Tuple{Any,Vararg{Any,N} where N}'>#</a>
**`SpineModel.@JuMPin`** &mdash; *Macro*.



```
JuMPin(dict, vars...)
```

Create one key in `dict` named after each one of `vars`, by taking the value from that variable.

**Example**

```julia
julia> @JuMPin(jfo, pgen, vmag);
julia> jfo["pgen"] == pgen
true
julia> jfo["vmag"] == vmag
true
```


<a target='_blank' href='https://gitlab.vtt.fi/spine/model/blob/ff46dedbc561f1497e958095143986eefc03bce5/src/data_io/util.jl#L53-66' class='documenter-source'>source</a><br>


<a id='Index-1'></a>

## Index

- [`SpineData.Spine_object`](index.md#SpineData.Spine_object-Tuple{Dict})
- [`SpineModel.JuMP_all_out`](index.md#SpineModel.JuMP_all_out)
- [`SpineModel.JuMP_all_out`](index.md#SpineModel.JuMP_all_out)
- [`SpineModel.JuMP_object`](index.md#SpineModel.JuMP_object)
- [`SpineModel.@JuMPin`](index.md#SpineModel.@JuMPin-Tuple{Any,Vararg{Any,N} where N})
- [`SpineModel.@JuMPout`](index.md#SpineModel.@JuMPout-Tuple{Any,Vararg{Any,N} where N})
- [`SpineModel.@JuMPout_suffix`](index.md#SpineModel.@JuMPout_suffix-Tuple{Any,Any,Vararg{Any,N} where N})
- [`SpineModel.@JuMPout_with_backup`](index.md#SpineModel.@JuMPout_with_backup-Tuple{Any,Any,Vararg{Any,N} where N})


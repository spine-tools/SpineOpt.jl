
<a id='SpineModel.jl-Documentation-1'></a>

# SpineModel.jl Documentation

- [SpineModel.jl Documentation](index.md#SpineModel.jl-Documentation-1)
    - [Functions](index.md#Functions-1)
        - [JuMP-friendly object](index.md#JuMP-friendly-object-1)
    - [Macros](index.md#Macros-1)
    - [Index](index.md#Index-1)


<a id='Functions-1'></a>

## Functions


<a id='JuMP-friendly-object-1'></a>

### JuMP-friendly object

<a id='SpineModel.JuMP_object' href='#SpineModel.JuMP_object'>#</a>
**`SpineModel.JuMP_object`** &mdash; *Function*.



```
JuMP_object(sdo::SpineDataObject, update_all_datatypes=true, JuMP_all_out=true)
```

A JuMP-friendly object from `sdo`. A JuMP-friendly object is simply a Julia `Dict`, constructed as follows:

  * For each object class, relationship class, and parameter in `sdo`, there is a key with its name in `jfo`.
  * The value of an 'object class key' is an `Array` of names of objects of that class.
  * The value of a 'relationship class key' is another `Dict`. The keys in this new `Dict` are the names of all objects this relationship is defined for. The value of each 'object key' is an `Array` of object names that are related to it.
  * The value of a 'parameter key' is another `Dict`. The keys in this new `Dict` are the names of all objects this parameter is defined for. The value of each 'object key' is the actual value of the parameter for that object. Data from the `json` field (if any) superseeds the data from the `value` field.

If `update_all_datatypes` is `true`, then the method tries to find out the julia `Type` that best fits all values for every parameter, and converts all values to that `Type`. (See `SpineData.update_all_datatypes!`.)

If `JuMP_all_out` is `true`, then the method also creates and exports convenience `functions` named after each key in `jfo`, that return the value of that key. See examples below.

**Example**

```julia
julia> jfo = JuMP_object(sdo);
julia> jfo["unit"]
4-element Array{String,1}:
 "coal_import"
 "gas_fired_power_plant"
...
julia> jfo["conversion_cost"]
Dict{String,Int64} with 4 entries:
  "gas_import" => 12
  "coal_fired_power_plant"  => 0
...
julia> jfo["unit_node"]
Dict{String,String} with 5 entries:
  "coal_fired_power_plant" => ["Leuven"]
  "coal_import"  => ["Leuven"]
  ...
  "Leuven" => ["coal_fired_power_plant", "coal_import", ...]
...
julia> unit()
4-element Array{String,1}:
 "coal_import"
 "gas_fired_power_plant"
...
julia> conversion_cost("gas_import")
12
julia> unit_node("Leuven")
4-element Array{String,1}:
 "coal_import"
 "gas_fired_power_plant"
...
```


<a target='_blank' href='https://gitlab.vtt.fi/spine/model/blob/abc0d3d3fc22df0fcd4f45a8bbfd52edc2c2e501/src/data/jfo.jl#L21-76' class='documenter-source'>source</a><br>

<a id='SpineModel.JuMP_object' href='#SpineModel.JuMP_object'>#</a>
**`SpineModel.JuMP_object`** &mdash; *Function*.



```
JuMP_object(source, update_all_datatypes=true, JuMP_all_out=true)
```

A JuMP-friendly object from `source`, where `source` is anything that can be converted into a `SpineDataObject` by the `SpineData.jl` package.

If `update_all_datatypes` is `true`, then the method tries to find out the julia `Type` that best fits all values for every parameter, and converts all values to that `Type`. (See `SpineData.update_all_datatypes!`.)

If `JuMP_all_out` is `true`, then the method also creates and exports convenience `functions` named after each key in `jfo`, that return the value of that key.

See also: [`JuMP_object(sdo::SpineDataObject, update_all_datatypes=true, JuMP_all_out=true)`](index.md#SpineModel.JuMP_object).


<a target='_blank' href='https://gitlab.vtt.fi/spine/model/blob/abc0d3d3fc22df0fcd4f45a8bbfd52edc2c2e501/src/data/jfo.jl#L1-15' class='documenter-source'>source</a><br>

<a id='SpineData.Spine_object-Tuple{Dict}' href='#SpineData.Spine_object-Tuple{Dict}'>#</a>
**`SpineData.Spine_object`** &mdash; *Method*.



```
SpineData.Spine_object(jfo::Dict)
```

A `SpineDataObject` from `jfo`, constructed by inverting the procedure described in [`JuMP_object(sdo::SpineDataObject, update_all_datatypes=true, JuMP_all_out=true)`](index.md#SpineModel.JuMP_object).


<a target='_blank' href='https://gitlab.vtt.fi/spine/model/blob/abc0d3d3fc22df0fcd4f45a8bbfd52edc2c2e501/src/data/jfo.jl#L205-210' class='documenter-source'>source</a><br>


<a id='Macros-1'></a>

## Macros

<a id='SpineModel.@JuMPout-Tuple{Any,Vararg{Any,N} where N}' href='#SpineModel.@JuMPout-Tuple{Any,Vararg{Any,N} where N}'>#</a>
**`SpineModel.@JuMPout`** &mdash; *Macro*.



```
JuMPout(dict, keys...)
```

Copy the value in `dict` of each one of `keys...` into a variable named after it.

**Example**

```julia
julia> @JuMPout(jfo, pmax, pmin);
julia> pmax == jfo["pmax"]
true
julia> pmin == jfo["pmin"]
true
```


<a target='_blank' href='https://gitlab.vtt.fi/spine/model/blob/abc0d3d3fc22df0fcd4f45a8bbfd52edc2c2e501/src/util.jl#L1-14' class='documenter-source'>source</a><br>

<a id='SpineModel.@JuMPout_suffix-Tuple{Any,Any,Vararg{Any,N} where N}' href='#SpineModel.@JuMPout_suffix-Tuple{Any,Any,Vararg{Any,N} where N}'>#</a>
**`SpineModel.@JuMPout_suffix`** &mdash; *Macro*.



```
JuMPout_suffix(dict, suffix, keys...)
```

Like [`@JuMPout(dict, keys...)`](index.md#SpineModel.@JuMPout-Tuple{Any,Vararg{Any,N} where N}) but appending `suffix` to the variable name.

**Example**

```julia
julia> @JuMPout_suffix(jfo, _new, pmax, pmin);
julia> pmax_new == jfo["pmax"]
true
julia> pmin_new == jfo["pmin"]
true
```


<a target='_blank' href='https://gitlab.vtt.fi/spine/model/blob/abc0d3d3fc22df0fcd4f45a8bbfd52edc2c2e501/src/util.jl#L21-34' class='documenter-source'>source</a><br>

<a id='SpineModel.@JuMPout_with_backup-Tuple{Any,Any,Vararg{Any,N} where N}' href='#SpineModel.@JuMPout_with_backup-Tuple{Any,Any,Vararg{Any,N} where N}'>#</a>
**`SpineModel.@JuMPout_with_backup`** &mdash; *Macro*.



```
JuMPout_with_backup(dict, backup, keys...)
```

Like [`@JuMPout(dict, keys...)`](index.md#SpineModel.@JuMPout-Tuple{Any,Vararg{Any,N} where N}) but also looking into `backup` if the key is not in `dict`.


<a target='_blank' href='https://gitlab.vtt.fi/spine/model/blob/abc0d3d3fc22df0fcd4f45a8bbfd52edc2c2e501/src/util.jl#L67-71' class='documenter-source'>source</a><br>

<a id='SpineModel.@JuMPin-Tuple{Any,Vararg{Any,N} where N}' href='#SpineModel.@JuMPin-Tuple{Any,Vararg{Any,N} where N}'>#</a>
**`SpineModel.@JuMPin`** &mdash; *Macro*.



```
JuMPin(dict, vars...)
```

Copy the value of each one of `vars` into a key in `dict` named after it.

**Example**

```julia
julia> @JuMPin(jfo, pgen, vmag);
julia> jfo["pgen"] == pgen
true
julia> jfo["vmag"] == vmag
true
```


<a target='_blank' href='https://gitlab.vtt.fi/spine/model/blob/abc0d3d3fc22df0fcd4f45a8bbfd52edc2c2e501/src/util.jl#L78-91' class='documenter-source'>source</a><br>


<a id='Index-1'></a>

## Index

- [`SpineData.Spine_object`](index.md#SpineData.Spine_object-Tuple{Dict})
- [`SpineModel.JuMP_object`](index.md#SpineModel.JuMP_object)
- [`SpineModel.JuMP_object`](index.md#SpineModel.JuMP_object)
- [`SpineModel.@JuMPin`](index.md#SpineModel.@JuMPin-Tuple{Any,Vararg{Any,N} where N})
- [`SpineModel.@JuMPout`](index.md#SpineModel.@JuMPout-Tuple{Any,Vararg{Any,N} where N})
- [`SpineModel.@JuMPout_suffix`](index.md#SpineModel.@JuMPout_suffix-Tuple{Any,Any,Vararg{Any,N} where N})
- [`SpineModel.@JuMPout_with_backup`](index.md#SpineModel.@JuMPout_with_backup-Tuple{Any,Any,Vararg{Any,N} where N})


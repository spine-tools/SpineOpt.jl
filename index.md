
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

<a id='SpineModel.JuMP_object-Tuple{AbstractString}' href='#SpineModel.JuMP_object-Tuple{AbstractString}'>#</a>
**`SpineModel.JuMP_object`** &mdash; *Method*.



```
JuMP_object(dsn)
```

A JuMP-friendly julia `Dict` translated from the database specified by `dsn`. The database should be in the Spine format. The argument `dsn` can either be an `AbstractString` or an `ODBC.DSN` object. See [`JuMP_object(sdo::SpineDataObject)`](index.md#SpineModel.JuMP_object-Tuple{SpineData.SpineDataObject}) for translation rules.

<a id='SpineModel.JuMP_object-Tuple{SpineData.SpineDataObject}' href='#SpineModel.JuMP_object-Tuple{SpineData.SpineDataObject}'>#</a>
**`SpineModel.JuMP_object`** &mdash; *Method*.



```
JuMP_object(sdo::SpineDataObject)
```

A JuMP-friendly julia `Dict` translated from `sdo`. Translation rules are outlined in the table below:

<table>   <tr>     <th rowspan=2>Spine object</th>     <th colspan=2>JuMP object</th>   </tr>   <tr>     <td><i>Key</i></td>     <td><i>Value</i></td>   </tr>   <tr>     <td>objects</td>     <td>Object_class</td>     <td>Array(Object, ...)</td>   </tr>   <tr>     <td>relationships</td>     <td>Relationship_class</td>     <td>Dict(Child_object => Parent_object, ...)</td>   </tr>   <tr>     <td>parameters</td>     <td>Parameter</td>     <td>Dict(Child => Value, ...)</td>   </tr> </table>

**Example**

```julia
julia> jfo = JuMP_object(sdo);
julia> jfo["gen"]
33-element Array{String,1}:
 "gen1"
 "gen2"
...
julia> jfo["pmax"]
Dict{String,Int64} with 33 entries:
  "gen24" => 197
  "gen4"  => 0
  "gen7"  => 400
...
julia> jfo["gen_bus"]
Dict{String,String} with 33 entries:
  "gen24" => "bus21"
  "gen4"  => "bus1"
...
```


<a id='Macros-1'></a>

## Macros

<a id='SpineModel.@JuMPout-Tuple{Any,Vararg{Any,N} where N}' href='#SpineModel.@JuMPout-Tuple{Any,Vararg{Any,N} where N}'>#</a>
**`SpineModel.@JuMPout`** &mdash; *Macro*.



```
JuMPout(dict, keys...)
```

Assign the value within `dict` of each key in `keys` to a variable named after that key.

**Example**

```julia
julia> @JuMPout(jfo, pmax, pmin);
julia> pmax == jfo["pmax"]
true
julia> pmin == jfo["pmin"]
true
```

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

<a id='SpineModel.@JuMPout_with_backup-Tuple{Any,Any,Vararg{Any,N} where N}' href='#SpineModel.@JuMPout_with_backup-Tuple{Any,Any,Vararg{Any,N} where N}'>#</a>
**`SpineModel.@JuMPout_with_backup`** &mdash; *Macro*.



```
JuMPout_with_backup(dict, backup, keys...)
```

Like [`@JuMPout(dict, keys...)`](index.md#SpineModel.@JuMPout-Tuple{Any,Vararg{Any,N} where N}) but also looking into `backup` if the key is not in `dict`.

<a id='SpineModel.@JuMPin-Tuple{Any,Vararg{Any,N} where N}' href='#SpineModel.@JuMPin-Tuple{Any,Vararg{Any,N} where N}'>#</a>
**`SpineModel.@JuMPin`** &mdash; *Macro*.



```
JuMPin(dict, vars...)
```

Assign the value of each variable in `vars` to a key in `dict` named after that variable.

**Example**

```julia
julia> @JuMPin(jfo, pgen, vmag);
julia> jfo["pgen"] == pgen
true
julia> jfo["vmag"] == vmag
true
```


<a id='Index-1'></a>

## Index

- [`SpineModel.JuMP_object`](index.md#SpineModel.JuMP_object-Tuple{AbstractString})
- [`SpineModel.JuMP_object`](index.md#SpineModel.JuMP_object-Tuple{SpineData.SpineDataObject})
- [`SpineModel.@JuMPin`](index.md#SpineModel.@JuMPin-Tuple{Any,Vararg{Any,N} where N})
- [`SpineModel.@JuMPout`](index.md#SpineModel.@JuMPout-Tuple{Any,Vararg{Any,N} where N})
- [`SpineModel.@JuMPout_suffix`](index.md#SpineModel.@JuMPout_suffix-Tuple{Any,Any,Vararg{Any,N} where N})
- [`SpineModel.@JuMPout_with_backup`](index.md#SpineModel.@JuMPout_with_backup-Tuple{Any,Any,Vararg{Any,N} where N})


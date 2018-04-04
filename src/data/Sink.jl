struct DictSink
    dict::Dict
    keys::Dict
end

function DictSink(sch::Data.Schema, ::Type{Data.Column}, ::Bool, args...; reference::Vector{UInt8}=UInt8[], kwargs...)
    sch.cols != 2 && error("Dict sink only accepts two column tables as input or something like that")
    T1, T2 = Data.types(sch)
    !isempty(args) && (T2 = Union{Missing,spine2julia[args[1][1]]})
    return DictSink(Dict{T1,T2}(), Dict{Int,T1}())
end

function DictSink(sink, sch::Data.Schema, ::Type{Data.Column}, append::Bool; reference::Vector{UInt8}=UInt8[])
    sch.cols != 2 && error("Dict sink only accepts two column tables as input or something like that")
    !isa(sink, DictSink) && error("Attempted to create a dictionary sink from a different sink type")
    T1, T2 = Data.types(sch)
    (T1 != keytype(sink.dict) || T2 != valtype(sink.dict)) && error("Incompatible key value types")
    return sink
end

Data.streamtypes(::Type{DictSink}) = [Data.Column]

function Data.streamto!(sink::DictSink, S::Type{Data.Column}, val, row::Int, col)
    dict = sink.dict
    keys = sink.keys
    offset = (row - 1) * length(val)
    if col == 1
        for (i,k) in enumerate(val)
            keys[offset + i] = k
        end
    elseif col == 2
        for (i,v) in enumerate(val)
            dict[keys[offset + i]] = v
        end
    end
end

Data.close!(sink::DictSink) = sink.dict

abstract type ArraySink end

function ArraySink(sch::Data.Schema, ::Type{Data.Column}, ::Bool, args...; reference::Vector{UInt8}=UInt8[], kwargs...)
    sch.cols != 1 && error("Array sink only accepts one column tables as input or something like that")
    S = Data.types(sch)
    return Array{S[1],1}()
end

function ArraySink(sink, sch::Data.Schema, ::Type{Data.Column}, append::Bool; reference::Vector{UInt8}=UInt8[])
    sch.cols != 1 && error("Array sink only accepts one column tables as input or something like that")
    !isa(sink, ArraySink) && error("Attempted to create an array sink from a different sink type")
    S = Data.types(sch)
    (S != eltype(sink)) && error("Incompatible types")
    return sink
end

Data.streamtypes(::Type{ArraySink}) = [Data.Column]

function Data.streamto!(sink::Array, S::Type{Data.Column}, val, row, col)
    for v in val
        push!(sink, v)
    end
end

Data.close!(sink::ArraySink) = sink

#Fix ODBC.Sink
ODBC.Sink(sch::Data.Schema, S::Type{Data.Column}, append::Bool, dsn::ODBC.DSN, table::AbstractString) = ODBC.Sink(sch, S, dsn, table; append=append)
ODBC.getptrlen(x::AbstractString) = pointer(Vector{UInt8}(x)), length(x), UInt8[]

#Extend ODBC.Sink to handle Any as String
Data.streamto!(sink::ODBC.Sink, S::Type{Data.Column}, column::Array{Any,1}, col) = Data.streamto!(sink, S, String.(column), col)

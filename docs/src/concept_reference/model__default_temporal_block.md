The [model\_\_default\_temporal\_block](@ref) relationship can be used to set a [model](@ref)-wide default
for the [node\_\_temporal\_block](@ref) and [units\_on\_\_temporal\_block](@ref) relationships.
Its main purpose is to allow users to avoid defining each relationship individually,
and instead allow them to focus on defining only the exceptions.
As such, any specific [node\_\_temporal\_block](@ref) or [units\_on\_\_temporal\_block](@ref)
relationships take priority over the [model\_\_default\_temporal\_block](@ref) relationship.

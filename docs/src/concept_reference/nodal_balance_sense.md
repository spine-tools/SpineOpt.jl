[nodal\_balance\_sense](@ref) determines whether or not a [node](@ref) is able to naturally
consume or produce energy. The default value, `==`, means that the [node](@ref) is unable to do any of that,
and thus it needs to be perfectly balanced. The vale `>=` means that the [node](@ref) is a *sink*,
that is, it can *consume* any amounts of energy. The value `<=` means that the [node](@ref) is a *source*,
that is, it can *produce* any amounts of energy.
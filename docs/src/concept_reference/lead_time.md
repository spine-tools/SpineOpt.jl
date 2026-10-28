The lead time of a [unit](@ref) or [connection](@ref) investment, i.e. the time between the investment decision and the start of operation.

In SpineOpt, the lead time only affects the economic representation of the investment costs:
when [multiyear\_economic\_discounting](@ref) is set, the investment payments are spread over the lead time and the economic lifetime.
It does not delay the availability of the invested capacity. Without [multiyear\_economic\_discounting](@ref), the lead time is not used.

The default is 0. See [Multi-year investments](@ref). For storages, see [storage\_lead\_time](@ref).

A map from a name to a value, which lets several parameters use the same value.

Any parameter whose value is a string that matches a name in [shared\_values](@ref) gets the corresponding value instead. For example, if [shared\_values](@ref) maps `wind_profile` to a time series, you can set the [availability\_factor](@ref) of several wind units to the string `wind_profile`, and they all use that time series. When the profile changes, you only need to update it in one place.

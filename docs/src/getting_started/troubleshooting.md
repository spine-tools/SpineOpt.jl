# [Troubleshooting](@id troubleshooting)

This troubleshooting section will grow over time when more issues arise. If your problem is not listed below, please create an [issue](https://github.com/spine-tools/SpineOpt.jl/issues).

## I cannot drag tools and databases from the ribbon to the design view
Have you created a new project? File > New project

## I get an error that the 'model' object is not defined in the database
That tends to happen when you accidentally switched your input and output in the Run SpineOpt tool.

## SpineOpt and SpineInterface are out of sync
Some of the development of SpineOpt depends on the development of SpineInterface and vice versa. At some points in time that can create an incompatibility between the two.

You could get an error like:

```julia
ERROR: LoadError: MethodError: no method matching MathOptInterface.EqualTo(::SpineInterface.Map{Symbol, SpineInterface.TimeSeries{Float64}})
Closest candidates are:
MathOptInterface.EqualTo(::T) where T\<:Number at C:\\Users\\prokjt.julia\\packages\\MathOptInterface\\vwZYM\\src\\sets.jl:223
```

It might just be a matter of time before the projects are updated. In the meanwhile you can check the issues whether someone has already reported the out-of-sync issue or otherwise create the issue yourself.

You can also try another version from the [installation](@ref installation) options.

## Julia 1.5 UUID ERROR

Using Julia 1.5.3 on Windows, installation fails with one of the following messages (or similar):

```julia
julia>  pkg"add SpineOpt"
   Updating registry at `C:\Users\manuelma\.julia\registries\General`
   Updating git-repo `https://github.com/JuliaRegistries/General.git`
   Updating registry at `C:\Users\manuelma\.julia\registries\SpineRegistry`
   Updating git-repo `https://github.com/spine-tools/SpineJuliaRegistry`
  Resolving package versions...
ERROR: expected package `UUIDs [cf7118a7]` to be registered
...
```

```julia
julia>  pkg"add SpineOpt"
   Updating registry at `C:\Users\manuelma\.julia\registries\SpineRegistry`
   Updating git-repo `https://github.com/spine-tools/SpineJuliaRegistry`
  Resolving package versions...
ERROR: cannot find name corresponding to UUID f269a46b-ccf7-5d73-abea-4c690281aa53 in a registry
...
```

The solution is to update the julia registry and install SpineOpt again.

1. Reset your Julia General registry. Copy/paste the following in the julia prompt:

   ```julia
   using Pkg
   rm(joinpath(DEPOT_PATH[1], "registries", "General"); force=true, recursive=true)
   withenv("JULIA_PKG_SERVER"=>"") do
       pkg"registry add"
   end
   ```

2. Try to install SpineOpt again.

## Windows 7

On Windows 7, installation fails with the following message (or similar):

```julia
julia>  pkg"add SpineOpt"
...
Downloading artifact: OpenBLAS32
Exception setting "SecurityProtocol": "Cannot convert null to type "System.Net.
SecurityProtocolType" due to invalid enumeration values. Specify one of the fol
lowing enumeration values and try again. The possible enumeration values are "S
sl3, Tls"."
At line:1 char:35
+ [System.Net.ServicePointManager]:: <<<< SecurityProtocol =
    + CategoryInfo          : InvalidOperation: (:) [], RuntimeException
    + FullyQualifiedErrorId : PropertyAssignmentException
...
```

The solution:

1. Install .NET 4.5 from here: https://www.microsoft.com/en-US/download/details.aspx?id=30653.

2. Install Windows management framework 3 or later, from here https://docs.microsoft.com/en-us/powershell/scripting/windows-powershell/wmf/overview?view=powershell-7.1.

3. Try to install SpineOpt again.
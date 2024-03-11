## SpineOpt.jl

[![Docs](https://img.shields.io/badge/docs-stable-blue.svg)](https://spine-tools.github.io/SpineOpt.jl/latest/index.html)
[![codecov](https://codecov.io/gh/spine-tools/SpineOpt.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/spine-tools/SpineOpt.jl) [![Join the chat at https://gitter.im/spine-tools/SpineOpt.jl](https://badges.gitter.im/spine-tools/SpineOpt.jl.svg)](https://gitter.im/spine-tools/SpineOpt.jl?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

A Julia package containing a state-of-the-art energy system optimization model.

### :loudspeaker: Community and how to ask help :rocket: 

There are four main ways to get help with SpineOpt.

1. Monthly user meetings for Spine Toolbox and SpineOpt. There you can connect with other users, present problems and exchange experiences. New and old users equally welcome. The meetings are held first Tuesday of every month at 3pm CEST [:calendar: ics zip](https://github.com/spine-tools/SpineOpt.jl/files/10497817/Spine.Toolbox.and.SpineOpt_.Exchange_.Q.A_.Help.zip)
and can be joined [here](https://teams.microsoft.com/l/meetup-join/19%3ameeting_MTA4MTZmMjMtNzk0ZS00ZjFkLWFjZjEtODVhNDc3Yjg5MjBj%40thread.v2/0?context=%7b%22Tid%22%3a%22021f8f00-6328-4916-b79c-b49b9a19a7d6%22%2c%22Oid%22%3a%22f45e2eeb-78d8-4230-903d-49e42a141be3%22%7d). For meeting updates, please checkout [this discussion](https://github.com/spine-tools/SpineOpt.jl/discussions/849).
2. [Gitter](https://app.gitter.im/#/room/#spine-tools_community:gitter.im) (i.e. Matrix) chat service. You need to register but allows to ask quick questions and hopefullly get quick answers.
3. [Discussion forum](https://github.com/spine-tools/SpineOpt.jl/discussions/categories/support) (support section) can be used when you don't know how to get something done or you don't quite know why something isn't working. It's highly appreciated if other users can contribute by helping each other (developers are short on time).
4. [Issue tracker](https://github.com/spine-tools/SpineOpt.jl/issues) should be used only when there is a missing feature or something should work but it's not working. Update your tools and test with latest software before submitting an issue. In case of new feature, make sure there is no existing issue. Issues reporting bugs should provide sufficient information to enable locating and fixing the bug.

### Citing SpineOpt

Please cite [this article](https://doi.org/10.1016/j.esr.2022.100902) when referring to SpineOpt in scientific writing.

```Ihlemann, M., Kouveliotis-Lysikatos, I., Huang, J., Dillon, J., O'Dwyer, C., Rasku, T., Marin, M., Poncelet, K., & Kiviluoma, J. (2022). SpineOpt: A flexible open-source energy system modelling framework. Energy Strategy Reviews, 43, [100902]. https://doi.org/10.1016/j.esr.2022.100902```

### Compatibility

This package requires [Julia](https://julialang.org/) 1.6 or higher.

### Installation

SpineOpt is designed to be used with [Spine Toolbox](https://github.com/spine-tools/Spine-Toolbox).

1. Install Spine Toolbox as described [here](https://github.com/spine-tools/Spine-Toolbox/blob/master/README.md#installation).

2. Download and install the latest version of Julia for your system as described [here](https://julialang.org/downloads).

3. Install SpineOpt using *one* of the below options:

	a. If you want to *use* SpineOpt but not develop it,
      we recommend installing it from the [Spine Julia Registry](https://github.com/spine-tools/SpineJuliaRegistry):

      1. Start the [Julia REPL](https://github.com/spine-tools/SpineOpt.jl/raw/master/docs/src/figs/win_run_julia.png).
      2. Copy and paste the following text into the julia prompt:
         ```julia
         using Pkg									# Use the package manager. Alternatively, use `]` in REPL
         pkg"registry add General https://github.com/spine-tools/SpineJuliaRegistry"	# Add SpineJuliaRegistry as an available registry for your Julia
         pkg"add SpineOpt"								# Install SpineOpt from the SpineJuliaRegistry
         ```

	b. If you want to both use and develop SpineOpt, we recommend installing it from sources:

      1. Git-clone this repository into your local machine.
      2. Git-clone the [SpineInterface repository](https://github.com/spine-tools/SpineInterface.jl) into your local machine.
      3. Start the [Julia REPL](https://github.com/spine-tools/SpineOpt.jl/raw/master/docs/src/figs/win_run_julia.png).
      4. Run the following commands from the julia prompt, replacing your local SpineOpt and SpineInterface paths
         ```julia
         using Pkg							# Use the package manager. Alternatively, use `]` in REPL
         pkg"dev <path-to-your-local-SpineInterface-repository>"	# Installs the local version of SpineInterface
         pkg"dev <path-to-your-local-SpineOpt-repository>"		# Installs the local version of SpineOpt
         ```
      5. If you want your local SpineOpt to use your local SpineInterface, you also need to `develop` the SpineInterface dependency manually:
         ```julia
         using Pkg							# Use the package manager. Alternatively, use `]` in REPL
         pkg"activate <path-to-your-local-SpineOpt-repository>"		# Activate the local SpineOpt environment
         pkg"dev <path-to-your-local-SpineInterface-repository>"	# Install the local SpineInterface into the local SpineOpt environment
         ```
      6. Lastly, you should probably make sure all the required dependencies are installed using the `instantiate` command:
	```julia
 	using Pkg							# Use the package manager. Alternatively, use `]` in REPL			
 	pkg"activate <path-to-your-local-SpineInterface-repository>"	# Activate the local SpineInterface environment
 	pkg"instantiate"						# Install SpineInterface dependencies
 	pkg"activate <path-to-your-local-SpineOpt-repository>"		# Activate the local SpineOpt environment
 	pkg"instantiate"						# Install SpineOpt dependencies (SpineInterface already installed locally in step 5)
 	```

4. Configure Spine Toolbox to use your Julia:

	a. Run Spine Toolbox.

	b. Go to **File** -> **Settings** -> **Tools**.

	c. Under **Julia**, enter the path to your Julia executable. It should look something like [this](https://github.com/spine-tools/SpineOpt.jl/raw/master/docs/src/figs/spinetoolbox_settings_juliaexe.png).  In case you have multiple Julia's in your system, the path should point to the same Julia version as is in your environment PATH.

	d. Press **Ok**.

It doesn't work? See our [Troubleshooting](#troubleshooting) section.

If you want to run SpineOpt outside Spine Toolbox, you need to configure SpineInterface PyCall using the instructions at the end of [SpineInterface installation instructions](https://github.com/spine-tools/SpineInterface.jl#installation).

### Upgrading

SpineOpt is constantly improving. To get the most recent version, upgrade SpineOpt using one of the following methods, depending on how you have installed it.

1. If you have installed SpineOpt from the registry:

	a. Start the [Julia REPL](https://github.com/spine-tools/SpineOpt.jl/raw/master/docs/src/figs/win_run_julia.png).

	b. Copy/paste the following text into the julia prompt (it will update the SpineOpt package from the [Spine Julia Registry](https://github.com/spine-tools/SpineJuliaRegistry)):

	```julia
	using Pkg
	pkg"up SpineOpt"
	```

2. If you have installed SpineOpt from the sources:

	a. Git-pull the latest master from this repository.

	b. Git-pull the latest master from the [SpineInterface repository](https://github.com/spine-tools/SpineInterface.jl).

	c. Start the [Julia REPL](https://github.com/spine-tools/SpineOpt.jl/raw/master/docs/src/figs/win_run_julia.png).

	d. Copy/paste the following text into the julia prompt:

	```julia
	using Pkg
	pkg"up SpineOpt"
	```

### Usage

For how to use SpineOpt in your Spine Toolbox projects,
please start from [here](https://spine-tools.github.io/SpineOpt.jl/latest/getting_started/setup_workflow/).
(We apologize for the lengthiness of that example. We're currently working on a minimal example that will get you started faster.)

### Documentation

SpineOpt documentation, including getting started guide and reference, can be found here: [Documentation](https://spine-tools.github.io/SpineOpt.jl/latest/index.html).
Alternatively, one can build the documentation locally, as it is bundled in with the source code.

First, **navigate into the SpineOpt main folder** and activate the `docs` environment from the julia package manager:

```julia
(SpineOpt) pkg> activate docs
(docs) pkg>
```

Next, in order to make sure that the `docs` environment uses the same SpineOpt version it is contained within,
install the package locally into the `docs` environment:

```julia
(docs) pkg> develop .
Resolving package versions...
<lots of packages being checked>
(docs) pkg>
```

Now, you should be able to build the documentation by exiting the package manager and typing:

```julia
julia> include("docs/make.jl")
```

This should build the documentation on your computer, and you can access it in the `docs/build/` folder.

### Compilation into a Julia system image

Sometimes it can be useful to 'compile' SpineOpt into a so-called system image. A system image is a binary library
that, roughly speaking, 'stores' all the compilation work from a previous Julia session.
If you start Julia with a system image, then Julia doesn't need to redo all that work and your code will be fast the
first time you run it.

**However** if you upgrade your version of
SpineOpt, any system images you might have created will not reflect that change - you will need to re-generate them.

To compile SpineOpt into a system image just do the following:

1. Install [PackageCompiler.jl](https://github.com/JuliaLang/PackageCompiler.jl).

1. Create a file with precompilation statements for SpineOpt:
	
	a. Start julia with `--trace-compile=file.jl`.

	b. Call `run_spineopt(url...)` with a nice DB - one that triggers most of SpineOpt's functionality you need.

	c. Quit julia.

1. Create the sysimage using the precompilation statements file:

	a. Start julia normally.

	b. Create the sysimage with PackageCompiler:   
      ```julia
      using PackageCompiler
      create_sysimage(; sysimage_path="SpineOpt.dll", precompile_statements_file="file.jl")
      ```

1. Start Julia with `--sysimage=SpineOpt.dll` to use the generated image.


### Troubleshooting

#### Problem
Some of the development of SpineOpt depends on the development of SpineInterface and vice versa. At some points in time that can create an incompatibility between the two.

You could get an error like:
```julia
ERROR: LoadError: MethodError: no method matching MathOptInterface.EqualTo(::SpineInterface.Map{Symbol, SpineInterface.TimeSeries{Float64}})
Closest candidates are:
MathOptInterface.EqualTo(::T) where T\<:Number at C:\\Users\\prokjt.julia\\packages\\MathOptInterface\\vwZYM\\src\\sets.jl:223
```

#### Solution
It might just be a matter of time before the projects are updated. In the meanwhile you can check the issues whether someone has already reported the out-of-sync issue or otherwise create the issue yourself.

In the meanwhile you can try another version. One option is to update directly from the github repository instead of the julia registry:

```julia
using Pkg
Pkg.add(url="https://github.com/spine-tools/SpineInterface.jl.git")
```

Another option is to use the developer version as described in the installation section.

#### Problem

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

#### Solution

1. Reset your Julia General registry. Copy/paste the following in the julia prompt:

	```julia
	using Pkg
	rm(joinpath(DEPOT_PATH[1], "registries", "General"); force=true, recursive=true)
	withenv("JULIA_PKG_SERVER"=>"") do
	    pkg"registry add"
	end
	```
2. Try to install SpineOpt again.

#### Problem

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

#### Solution

1. Install .NET 4.5 from here: https://www.microsoft.com/en-US/download/details.aspx?id=30653.

2. Install Windows management framework 3 or later, from here https://docs.microsoft.com/en-us/powershell/scripting/windows-powershell/wmf/overview?view=powershell-7.1.

3. Try to install SpineOpt again.


### Reporting Issues and Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md)

### License

SpineOpt is licensed under GNU Lesser General Public License version 3.0 or later.

### Acknowledgements

<center>
<table width=500px frame="none">
<tr>
<td valign="middle" width=100px>
<img src=docs/src/figs/eu-emblem-low-res.jpg alt="EU emblem" width=100%></td>
<td valign="middle">This work has been partially supported by EU project Mopo (2023-2026), which has received funding from European Climate, Infrastructure and Environment Executive Agency under the European Union’s HORIZON Research and Innovation Actions under grant agreement N°101095998.</td>
<tr>
<td valign="middle" width=100px>
<img src=docs/src/figs/eu-emblem-low-res.jpg alt="EU emblem" width=100%></td>
<td valign="middle">This work has been partially supported by EU project Spine (2017-2021), which has received funding from the European Union’s Horizon 2020 research and innovation programme under grant agreement No 774629.</td>
</table>
</center>

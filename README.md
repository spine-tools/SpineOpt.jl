## SpineOpt.jl

[![Docs](https://img.shields.io/badge/docs-stable-blue.svg)](https://spine-project.github.io/SpineOpt.jl/latest/index.html)
[![codecov](https://codecov.io/gh/Spine-project/SpineOpt.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/Spine-project/SpineOpt.jl)

A package to run an energy system integration model called SpineOpt.

### :loudspeaker:UPDATE: Community :rocket: 

To connect with other users, to identify problems and exchange experiences, we will organize monthly early-user meetings for Spine Toolbox and SpineOpt. The meetings will be held every last Wednesday of the month at 10am CEST [:calendar: ics zip](https://github.com/Spine-project/SpineOpt.jl/files/9149471/Spine.Toolbox.and.SpineOpt.Exchange.QA.Help.zip)
) and can be joined [here](https://teams.microsoft.com/l/meetup-join/19%3ameeting_YjlhOWNmZjYtMDUxMC00MWViLTllMGUtNGI0NWY5NzY2YTU4%40thread.v2/0?context=%7b%22Tid%22%3a%22d7ab8571-7881-415a-b0c2-b5a933c86ee8%22%2c%22Oid%22%3a%227ff67982-a736-42fa-ade6-994bb97d94a8%22%7d).

### Compatibility

This package requires [Julia](https://julialang.org/) 1.2 or later.

### Installation

SpineOpt is designed to be used with [Spine Toolbox](https://github.com/Spine-project/Spine-Toolbox).

1. Install Spine Toolbox as described [here](https://github.com/Spine-project/Spine-Toolbox/blob/master/README.md#installation).

2. Download and install the latest version of Julia for your system as described [here](https://julialang.org/downloads).

3. Install SpineOpt using *one* of the below options:

	a. If you want to *use* SpineOpt but not develop it,
      we recommend installing it from the [Spine Julia Registry](https://github.com/Spine-project/SpineJuliaRegistry):

      1. Start the [Julia REPL](https://github.com/Spine-project/SpineOpt.jl/raw/master/docs/src/figs/win_run_julia.png).
      2. Copy and paste the following text into the julia prompt:
         ```julia
         using Pkg
         pkg"registry add General https://github.com/Spine-project/SpineJuliaRegistry"
         pkg"add SpineOpt"
         ```

	b. If you want to both use and develop SpineOpt, we recommend installing it from sources:

      1. Git-clone this repository into your local machine.
      2. Git-clone the [SpineInterface repository](https://github.com/Spine-project/SpineInterface.jl) into your local machine.
      3. Start the [Julia REPL](https://github.com/Spine-project/SpineOpt.jl/raw/master/docs/src/figs/win_run_julia.png).
      4. Run the following commands from the julia prompt, replacing your local SpineOpt and SpineInterface paths
         ```julia
         using Pkg
         pkg"dev <path-to-your-local-SpineInterface-repository>"
         pkg"dev <path-to-your-local-SpineOpt-repository>"
         ```

4. Configure Spine Toolbox to use your Julia:

	a. Run Spine Toolbox.

	b. Go to **File** -> **Settings** -> **Tools**.

	c. Under **Julia**, enter the path to your Julia executable. It should look something like [this](https://github.com/Spine-project/SpineOpt.jl/raw/master/docs/src/figs/spinetoolbox_settings_juliaexe.png).

	d. Press **Ok**.

It doesn't work? See our [Troubleshooting](#troubleshooting) section.

### Upgrading

SpineOpt is constantly improving. To get the most recent version, just:

1. Start the [Julia REPL](https://github.com/Spine-project/SpineOpt.jl/raw/master/docs/src/figs/win_run_julia.png).

2. Copy/paste the following text into the julia prompt
(it will update the SpineOpt package from the [Spine Julia Registry](https://github.com/Spine-project/SpineJuliaRegistry)):

	```julia
	using Pkg
	pkg"up SpineOpt"
	```

### Usage

For an example of how to use SpineOpt in your Spine Toolbox projects,
please see [here](https://spine-toolbox.readthedocs.io/en/latest/case_study_a5.html).
(We apologize for the lengthiness of that example. We're currently working on a minimal example that will get you started faster.)

### Documentation

SpineOpt documentation, including getting started guide and reference, can be found here: [Documentation](https://spine-project.github.io/SpineOpt.jl/latest/index.html).
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

### Troubleshooting

#### Problem

Using Julia 1.5.3 on Windows, installation fails with one of the following messages (or similar):

```julia
julia>  pkg"add SpineOpt"
   Updating registry at `C:\Users\manuelma\.julia\registries\General`
   Updating git-repo `https://github.com/JuliaRegistries/General.git`
   Updating registry at `C:\Users\manuelma\.julia\registries\SpineRegistry`
   Updating git-repo `https://github.com/Spine-project/SpineJuliaRegistry`
  Resolving package versions...
ERROR: expected package `UUIDs [cf7118a7]` to be registered
...
```
```julia
julia>  pkg"add SpineOpt"
   Updating registry at `C:\Users\manuelma\.julia\registries\SpineRegistry`
   Updating git-repo `https://github.com/Spine-project/SpineJuliaRegistry`
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

### Citing SpineOpt

Please cite [this article](https://doi.org/10.1016/j.esr.2022.100902) when referring to SpineOpt in scientific writing.

### Acknowledgements

<center>
<table width=500px frame="none">
<tr>
<td valign="middle" width=100px>
<img src=https://ec.europa.eu/regional_policy/images/information/logos/eu_flag.jpg alt="EU emblem" width=100%></td>
<td valign="middle">This project has received funding from the European Union’s Horizon 2020 research and innovation programme under grant agreement No 774629.</td>
</table>
</center>

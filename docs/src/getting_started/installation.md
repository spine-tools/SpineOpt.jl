# [Installation](@id installation)

There are different ways to install SpineOpt. It is recommended to first read through the different options and perhaps even the [troubleshooting](@ref troubleshooting) section before deciding which approach suits you the most. Though, we also provide a quick guideline below.

* If you do not use julia on your system for other projects, by far the easiest option is to install SpineOpt through Spine Toolbox.
* If want more control over your julia installation or want to safeguard your other projects,  you can create a julia environment and/or install SpineOpt yourself through the Julia REPL. (The instructions do not include the configuration of 'PyCall', see warning below).
* Yet, the most versatile and flexible way to install SpineOpt is to install it from source.

Once SpineOpt is installed, you can verify whether it works by following the [Recommended workflow](@ref recommended_workflow). If there are any troubles with the installation (which, to be honest, is very likely due to the many moving parts), you can try [Troubleshooting](@ref troubleshooting).

!!! warning
    Some of the development of SpineOpt depends on the development of SpineInterface (used to communicate with a spine database) and vice versa. At some points in time that can create an incompatibility between the two. It may just be a matter of time before the projects are updated. In the meanwhile you can check the issues on github whether someone has already reported the out-of-sync issue or otherwise create the issue yourself.

    These type of issues are (created and) resolved faster in the source as the julia registry is not updated that often.

    Also, SpineInterface depends on PyCall to access the spine db api written in Python. The correct configuration of PyCall is not always straightforward. Especially if you use PyCall in different virtual environments.

    Instructions for PyCall configuration are also provided in the instructions for installation from source.

## Installation through Spine Toolbox
Prerequisites:
+ [Spine Toolbox](https://github.com/Spine-tools/Spine-Toolbox?tab=readme-ov-file#installation)

### Open Spine Toolbox

To open Spine Toolbox we'll need to enter a few commands in the command line. If you've setup Spine Toolbox in a Python (or conda) environment, we first need to activate that environment. Then, we can open Spine Toolbox with the 'spinetoolbox' command.

!!! tip
    You can do this manually everytime but here we show how you can make a small script such that Spine Toolbox behaves more like the other programs on your system, e.g. you can make a shortcut somewhere and/or run the file by double clicking.

    For Windows, create a '.bat' file (you can make a text file and change the extension from '.txt' to '.bat'). The following lines of code should be pasted in that file. Make sure to adjust the path to the actual path of the Python environment that you used to install Spine Toolbox.
    ```cmd
    cd path/to/python/environment/folder
    Scripts/activate
    spinetoolbox
    ```

    For Linux, create a '.sh' (bash) file. The following lines of code should be pasted in that file. Make sure to adjust the path to the actual path of the Python environment that you used to install Spine Toolbox.
    ```bash
    #!/bin/bash
    cd path/to/python/environment/folder
    source bin/activate
    spinetoolbox
    ```
    You'll also have to give the file the necessary permissions. Depending on your distribution, there may be a built-in way to do this. Otherwise run the 'chmod' command:
    ```bash
    chmod +x path/to/script_folder/script_name.sh
    ```

### Spine Toolbox settings
Spine Toolbox has a built-in way to install Julia and SpineOpt
1. Go to File > Settings > Tools
2. Under the Julia section, point to your julia installation or click the 'Install Julia' button.
3. Once Julia is installed, under the same section as before, click the 'Add/Update SpineOpt' button to install SpineOpt.
4. Go to Plugins > Install plugins 
5. Select the SpineOpt plugin to add a ribbon to Spine Toolbox with easy access to some basic tools for SpineOpt (including a template for a SpineOpt (spine) database and a tool to run SpineOpt).

### Upgrade
To upgrade SpineOpt, click the 'Add/Update SpineOpt' button in the settings again.

## Installation through the Julia REPL
Prerequisites:
+ [Julia](https://julialang.org/) >= 1.8

!!! warning
    We've encountered performance issues with Julia 1.9 so that version is not recommended. The latest version should be fine.

!!! info
    You can install Julia through Python:
    ```
    pip install jill
    jill install
    ```

### 1. [optional] Create a julia environment

Ideally you run SpineOpt in a julia environment (although this is optional if you don't expect conflicts between your projects). To create a julia environment, open the Julia REPL in the folder where you want to store the environment and execute the following commands:
```julia
import Pkg # the package manager
Pkg.activate("jenv")# create and activate the environment named 'jenv' in the current working directory
```

!!! info
    To open the Julia REPL, find and run the julia executable on your system or open the command line (cmd, powershell or the Terminal app on windows) and type 'julia' (julia needs to be part of the registry to work properly).

### 2. install SpineOpt (in the environment)

To install SpineOpt, execute the following commands in the Julia REPL (again in the folder of the julia environment):
```julia
import Pkg # the package manager
Pkg.activate("jenv") # only needed if you want to use a virtual environment
Pkg.Registry.add("General")
Pkg.Registry.add(Pkg.RegistrySpec(url = "https://github.com/spine-tools/SpineJuliaRegistry")) # Add SpineJuliaRegistry as an available registry for your Julia
Pkg.add("SpineOpt") # Install SpineOpt from the SpineJuliaRegistry
```

The SpineOpt package is now available and ready to use in your julia scripts. If you have installed SpineOpt in a virtual environment, don't forget to activate the virtual environment when you try to run your scripts.

### 3. [optional] configure Spine Toolbox to use SpineOpt

If you want to use this SpineOpt package in Spine Toolbox, make sure that the settings in Spine Toolbox point to the correct julia executable (and environment folder) where you installed SpineOpt (File > Settings > Tools).

ALso, select the SpineOpt plugin to add a ribbon to Spine Toolbox with easy access to some basic tools for SpineOpt (including a template for a SpineOpt (spine) database and a tool to run SpineOpt).

### Upgrade
To upgrade SpineOpt through the Julia REPL (in the same environment folder as before), execute the following commands:
```julia
import Pkg
Pkg.activate("jenv") # only needed if you used a virtual environment
Pkg.update("SpineOpt")
```

## Installation from source
Prerequisites:
+ [Spine Toolbox](https://github.com/Spine-tools/Spine-Toolbox?tab=readme-ov-file#installation)
+ [Julia](https://julialang.org/) >= 1.8
+ [Git](https://git-scm.com/)

!!! info
    You can install Julia through Python:
    ```cmd
    pip install jill
    jill install
    ```

    You can check whether these are installed correctly by opening the commandline and typing:
    ```cmd
    git --version
    julia --version
    spinetoolbox
    ```

As mentioned before, SpineOpt depends on SpineInterface and SpineInterface depends on PyCall. Therefore, here we do not only install SpineOpt from source but SpineInterface as well and we pay special attention to the correct configuration of PyCall. We assume that if you only want to configure PyCall or only want to install SpineOpt from source, you are able to deduce yourself which steps of these instructions you need and which you don't.

### 1. Choose a folder to install spine tools.

Some system administered systems may not like you installing programs outside of your user folder so you can choose a folder there, e.g. 'spinetools'.

### 2. Download files from git through the commandline

Open the commandline in the folder you have chosen to install spine tools and type the following commands:

```git
git clone https://github.com/spine-tools/SpineInterface.jl.git
git clone https://github.com/spine-tools/SpineOpt.jl.git
```

### 3. [optional] Select a branch through the commandline

Perhaps you want to select a specific branch or release instead of the latest master branch. In that case you can type something along the line of the following (still in the commandline):
```
cd SpineInterface.jl
git fetch
git checkout -b 0.8-dev origin/0.8-dev
cd ..
cd SpineOpt.jl
git fetch
git checkout tags/v0.8.1 -b v081
cd ..
```
In this case we have selected the 0.8-dev branch for SpineInterface and the 0.8.1 release of SpineOpt.

### 4. Create a julia environment through the Julia REPL

Navigate to the folder that you chose for installing spine tools. If not done so already, create a new folder to store the julia environment. Open the Julia REPL in that folder and type the following commands:
```Julia
import Pkg
Pkg.activate("jenv")
```

### 5. Install SpineInterface through the Julia REPL

Once the environment is created we can install the downloaded source files one by one. Go to the SpineInterface.jl folder and open the Julia REPL there.
```Julia
path_environment = joinpath(dirname(@__DIR__),"environments","jenv") # only works if you have the folder structure as in these instructions, otherwise you put the path to your environment here
path_spineinterface = joinpath(@__DIR__)
import Pkg
Pkg.activate(path_environment)
Pkg.instantiate()
Pkg.develop(path=path_spineinterface)
```

### 6. Install SpineOpt through the Julia REPL

And we do the same for SpineOpt. Go to the SpineOpt.jl folder and open the Julia REPL there.
```Julia
path_environment = joinpath(dirname(@__DIR__),"environments","jenv") # only works if you have the folder structure as in these instructions, otherwise you put the path to your environment here
path_spineopt = joinpath(@__DIR__)
import Pkg
Pkg.activate(path_environment)
Pkg.instantiate()
Pkg.develop(path=path_spineopt)
```

### 7. Configure PyCall through the Julia REPL

SpineOpt and SpineInterface are now installed from source. The next step is to ensure that PyCall is configured correctly. You can also use these commands to configure PyCall for your different projects. Go to the folder where you decided to install spine tools and again open the Julia REPL.
```julia
path_environment = joinpath(@__DIR__,"environments","jenv")
path_python = joinpath(@__DIR__,"environments","penv","Scripts","python") # may be different depending on your installation of Spine Toolbox
import Pkg
Pkg.activate(path_environment)
import PyCall
ENV["PYTHON"] = path_python
Pkg.build("PyCall")
```

Close the Julia REPL and reopen it. Type the following commands to check whether PyCall points to the correct python (environment).
```julia
path_environment = joinpath(@__DIR__,"environments","jenv")
import Pkg
Pkg.activate(path_environment)
import PyCall
println(PyCall.pyprogramname)
```

!!! warning
    You have to adjust this code for the correct paths, in particular the path for your python environment for Spine Toolbox (as the installation instructions for Spine Toolbox may slightly differ from these instructions).

### 8. Configure Julia in the Spine Toolbox settings

If you want to use this SpineOpt package in Spine Toolbox, make sure that the settings in Spine Toolbox point to the correct julia executable (and environment folder) where you installed SpineOpt (File > Settings > Tools).

### 9. Install the SpineOpt plugin

Select the SpineOpt plugin to add a ribbon to Spine Toolbox with easy access to some basic tools for SpineOpt (including a template for a SpineOpt (spine) database and a tool to run SpineOpt).

### Upgrade

To upgrade spine tools in this configurations, take the following steps:
1. `Git pull` in each of the source folders
2. Activate the julia environment and run the `Pkg.update()` command. (You may need to go through the steps with `Pkg.instantiate()` if there are new dependencies.)
3. Reconfigure PyCall for good measure.
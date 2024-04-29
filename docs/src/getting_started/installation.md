# Installation

## Compatibility

This package requires Julia 1.2 or later.

Some of the development of SpineOpt depends on the development of SpineInterface and vice versa. At some points in time that can create an incompatibility between the two. It might just be a matter of time before the projects are updated. In the meanwhile you can check the issues on github whether someone has already reported the out-of-sync issue or otherwise create the issue yourself. In the meanwhile you can try another version. One option is to update the packages directly from the github repository instead of the julia registry. Another option is to use the developer version. The installation procedure for both of these options are described in the readme of the github repository.

## Installation


If you haven't yet installed the tools yet, please follow the installation guides: 
- For Spine Toolbox: <https://github.com/spine-tools/Spine-Toolbox#installation>
- For SpineOpt: <https://github.com/spine-tools/SpineOpt.jl#installation>

If you are not sure whether you have the latest version, please upgrade to ensure compatibility with this guide.
- For Spine Toolbox:
	- If installed with pipx, then use `python -m pipx upgrade spinetoolbox`
	- If installed from sources using git, then<br>
	    `git pull`<br>
		`python -m pip install -U -r requirements.txt`<br>
- For SpineOpt: https://github.com/spine-tools/SpineOpt.jl#upgrading

Thanks for taking the plunge!

## Reporting Issues

* It's always good to start with a quick search for an existing issue to post on, or related issues for context, before opening a new issue
* Including minimal examples is greatly appreciated
* If it's a bug, or unexpected behavior, reproducing on the latest development version (`Pkg.checkout("SpineOpt")`) is a good check and can streamline the process, along with including the first two lines of output from `versioninfo()`

## Contributing

* Feel free to open, or comment on, an issue and solicit feedback early on, especially if you're unsure about aligning with design goals and direction, or if relevant historical comments are ambiguous
* When developing a new functionality or modifying an existing one, considering the following to work on (possibly in one pull request)
  * Add the new functionality or modifying an existing one
  * Pair the new functionality with tests, and bug fixes with tests that fail pre-fix. Increasing test coverage as you go is always nice
  * Update the documentation (seen implementation details in the documentation for some advanced features)
* Aim for atomic commits, if possible, e.g. `change 'foo' behavior like so` & `'bar' handles such and such corner case`, rather than `update 'foo' and 'bar'` & `fix typo` & `fix 'bar' better`
* Pull requests will be tested against release and development branches of Julia, so using `Pkg.test("SpineOpt")` as you develop can be helpful
* The style guidelines outlined below are not the personal style of most contributors, but for consistency throughout the project, we should adopt them
* If you'd like to join our monthly developer meetings, just send us a message (<spine_info@vtt.fi>)

## Using JuliaFormatter

We use [JuliaFormatter.jl](https://github.com/domluna/JuliaFormatter.jl) for code
formatting and style.

To install it, open Julia REPL, for example, by typing in the
command line:

```bash
julia
```

> **Note**:
> `julia` must be part of your environment variables to call it from the
> command line.

Then press <kbd>]</kbd> to enter the package mode.
    In the package mode, enter the following:

```julia
pkg> activate
pkg> add JuliaFormatter
```

In VSCode, you can activate "Format on Save" for `JuliaFormatter`.
To do so, open VSCode Settings (<kbd>Ctrl</kbd> + <kbd>,</kbd>), then in "Search
Settings", type "Format on Save" and tick the first result.

## Releases
Releases are discussed among the developers first. When there is a new release version for SpineOpt, it can proceed with it's own release. However, when there is an update to SpineInterface (that affects SpineOpt), both of them need a new version number and release. Here are the steps:

SpineInterface (in case SpineInterface has been updated in a way that affects SpineOpt):
* Update project.toml, version: x.y.z (using semantic version numbering)
* Update registry following [SpineJuliaRegistry](https://github.com/spine-tools/SpineJuliaRegistry)
* Make a new release (and tag) for SpineInterface with the same version x.y.z

SpineOpt (if either has been udpated):
* update project.toml, version: a.b.c & point to correct SpineInterface version x.y.z (same as above)
* Update registry following [SpineJuliaRegistry](https://github.com/spine-tools/SpineJuliaRegistry)
* Make a new release (and tag) a.b.c for SpineOpt

If Spine Toolbox gets an update that requires changes in SpineInterface, then it also needs to be included in the loop. In this case, before updating SpineInterface, make a branch that can hold the version that worked with the old Spine Toolbox (and similarly should be done in Spine Toolbox side). The branch should be named e.g. v0.8.x-release.

## Further questions

* For developers there is some additional information in the implementation details (e.g. how to write a constraint).
* You can talk to your fellow developers over gitter if the above is insufficient.

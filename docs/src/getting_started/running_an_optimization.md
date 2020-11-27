# Running an Optimization

TODO: Explain how to run optimizations using *SpineOpt* through *Spine Toolbox*. This section would benefit greatly
if there was some form of an example system bundled in with *SpineOpt*, maybe even a pre-made *Spine Toolbox* project
that would allow users to simply load it into *Toolbox* and press execute. 

## Quick start guide

Once `SpineOpt` is installed, to use it in your programs you just need to say:

```julia
julia> using SpineOpt
```

To run SpineOpt for a SpineOpt database, say:

```julia
julia> run_spineopt("...url of a SpineOpt database...")
```

In what follows, we demonstrate how to setup a database for a simple example through
[Spine Toolbox](https://github.com/Spine-project/Spine-Toolbox).
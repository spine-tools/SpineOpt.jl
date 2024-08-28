# How to compile into a Julia system image

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
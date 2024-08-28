# How to print the model

As the SpineOpt model formulation is quite complex and can change depending on a few parameters (some parts of the formulation can be activated or deactivated), it can be useful to print the model that SpineOpt sends to JuMP. There are a few ways to do this.

The model that SpineOpt sends to JuMP can be saved to a file. It is not the nicest file to read but at the very least you can find the used variables and parameter values.

To write that file you need to set the `write_mps_file` parameter of the model object to `write_mps_always`.

SpineOpt will write the file to the working directory. If you are using Spine Toolbox that working directory will be the Spine Toolbox work folder which is typically in your user directory e.g. C:\\Users\\username\\.spinetoolbox\\work\\run\_spineopt\_gibberish\_toolbox\\model\_diagnostics.mps

An alternative approach is to directly use the [`write_model_file(m;file_name)`](https://github.com/spine-tools/SpineOpt.jl/blob/master/src/util/write_information_files.jl) function, where `m` is a reference to your model and `file_name` is the filename you want the model file written to.

`m` can be obtained from the call to `run_spineopt()`. In Spine Toolbox, more particularly the run\_SpineOpt tool, you will have `m=run_spineopt()`. That means that you can call `write_model_file(m;file_name)` in the console once SpineOpt has finished executing and the console remains open.

```julia
using SpineOpt
m = run_spineopt(
    raw"sqlite:///C:\path\to\your\inputputdb.sqlite", 
    raw"sqlite:///C:\path\to\your\outputdb.sqlite";
    optimize=false
    )
write_model_file(m; file_name="<path-with-file-name>")
```

The resulting file has the extension `*.so_model` in the especified path.

!!! note
    If running the previous code gives you an error, please try replacing the last line with `SpineOpt.write_model_file(m; file_name="<path-with-file-name>")`. This error might appear in previous versions of SpineOpt where the `write_model_file` was not exported as part of the SpineOpt package.

In either case, here are some tips if you are using this file for debugging. The file can be very large so often it is helpful to create a minimum example of your model with only one or two timesteps. In addition, in the call to run\_spineopt() you can add the keyword argument `optimize=false`, as in the example above, so it will just build the model and not attempt to solve it.

The function `write_model_file` formats the file nicely for the user's readability. However, if the model is too large, it skips the number of rows it prints. If you still want the complete file, you can also use the JuMP function `write_to_file` to print the model. For more details on the function, please visit the JuMP package documentation.

```julia
using JuMP
JuMP.write_to_file(m, filename="<path-with-file-name>")
```

# How to print the model

As the SpineOpt model formulation is quite complex and can change depending on a few parameters (some parts of the formulation can be activated or deactivated), it can be useful to print the model that SpineOpt sends to JuMP. There are a few ways to do this.

The model that SpineOpt sends to JuMP can be saved to a file. It is not the nicest file to read but at the very least you can find the used variables and parameter values.

To write that file you need to set the `write_mps_file` parameter of the model object to `write_mps_always`.

SpineOpt will write the file to the working directory. If you are using Spine Toolbox that working directory will be the Spine Toolbox work folder which is typically in your user directory e.g. C:\\Users\\username\\.spinetoolbox\\work\\run\_spineopt\_gibberish\_toolbox\\model\_diagnostics.mps

An alternative approach is to directly use the write\_model\_file(m, filename) command in which m is a reference to your model and filename is the filename you want the model file written to.

m can be obtained from the call to run\_spineopt(). In Spine Toolbox, more particularly the run\_SpineOpt tool, you will have m=run\_spineopt(). That means that you can call write\_model\_file(m,filename) in the console once SpineOpt has finished executing and the console remains open.

In either case, here are some tips if you are using this file for debugging. The file can be very large so often it is helpful to create a minimum example of your model with only one or two timesteps. Also, in the call to run\_spineopt() you can add the keyword argument optimize=false so it will just build the model and not attempt to solve it.
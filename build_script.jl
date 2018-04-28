## This script ensures that there is a local copy of the package.
Pkg.update()
Pkg.clone(joinpath(pwd(), "data"), "SpineData")
Pkg.status("Graphs")
Pkg.checkout("SpineData", "manuelma")
Pkg.build("SpineData")
Pkg.clone(pwd(), "SpineModel")
Pkg.checkout("SpineModel", "manuelma")
Pkg.build("SpineModel")

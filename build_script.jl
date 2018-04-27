## This script ensures that there is a local copy of the package.
Pkg.update()
Pkg.clone(joinpath(dirname(pwd()), "data"), "SpineData")
Pkg.checkout("SpineData", "manuelma")
Pkg.build("SpineData")
Pkg.clone(pwd(), "SpineModel")
Pkg.checkout("SpineModel", "manuelma")
Pkg.build("SpineModel")

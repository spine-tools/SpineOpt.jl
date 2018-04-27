## This script ensures that there is a local copy of the package.
Pkg.update()
Pkg.clone(pwd())
Pkg.checkout("SpineModel", "manuelma")
Pkg.build("SpineModel")

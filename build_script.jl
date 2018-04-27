## This script ensures that there is a local copy of the package.
Pkg.update()
Pkg.clone("https://gitlab.vtt.fi/spine/data.git", "SpineData")
Pkg.checkout("SpineData", "manuelma")
Pkg.build("SpineData")
Pkg.clone(pwd())
Pkg.checkout("SpineModel", "manuelma")
Pkg.build("SpineModel")

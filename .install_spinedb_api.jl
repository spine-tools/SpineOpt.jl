using Pkg
pkg"registry add General"
pkg"registry add https://github.com/Spine-project/SpineJuliaRegistry"
pkg"add PyCall"
using PyCall
python = PyCall.pyprogramname
run(`$python -m pip install --user setuptools`)
run(`$python -m pip install --user git+https://github.com/Spine-project/Spine-Database-API`)
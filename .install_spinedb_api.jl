using Pkg
pkg"registry add General"
pkg"registry add https://github.com/spine-tools/SpineJuliaRegistry"
pkg"add PyCall"
using PyCall
python = PyCall.pyprogramname
run(`$python -m pip install --user setuptools-scm`)
run(`$python -m pip install --user git+https://github.com/spine-tools/Spine-Database-API@8538a199ac9b6a2f036054b426a25efb2cee8e65`)

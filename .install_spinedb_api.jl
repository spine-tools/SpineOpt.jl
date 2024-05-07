using Pkg
pkg"registry add General"
pkg"registry add https://github.com/spine-tools/SpineJuliaRegistry"
pkg"add PyCall"
using PyCall
python = PyCall.pyprogramname
run(`$python -m pip install --user setuptools-scm`)
run(`$python -m pip install --user git+https://github.com/spine-tools/Spine-Database-API.git@release-0.30.5\#egg=spinedb_api`)

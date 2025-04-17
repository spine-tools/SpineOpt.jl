using Pkg
pkg"registry add General"
pkg"add PyCall"
using PyCall
python = PyCall.pyprogramname
if isempty(ARGS)
    spine_db_api_git_ref = "master"
else
    spine_db_api_git_ref = ARGS[1]
end
run(`$python -m pip install --user setuptools-scm`)
run(`$python -m pip install --user git+https://github.com/spine-tools/Spine-Database-API@$spine_db_api_git_ref`)
#############################################################################
# Copyright (C) 2017 - 2021  Spine Project
#
# This file is part of SpineOpt.
#
# SpineOpt is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# SpineOpt is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#############################################################################

using Pkg

# Activate the current project environment and install required packages
Pkg.activate(dirname(@__FILE__))
Pkg.instantiate()

using ArgParse
using SpineOpt: run_spineopt

# Parse command line arguments
s = ArgParseSettings(
    description="SpineOpt energy system modelling tool",
    add_version=true,
    version=string(Pkg.project().version)
)
@add_arg_table! s begin
    "url_in"
        help = "Input database url"
        required = true
    "url_out"
        help = "Input database url"
        required = false
    "--upgrade", "-U"
        help = "Wheter to automatically upgarde database"
        action = :store_true
    # TODO: Add more arguments of `run_spineopt()`
end
args = parse_args(ARGS, s)

# Set output url to input if not defined
if isnothing(args["url_out"])
    args["url_out"] = args["url_in"]
end

run_spineopt(
    args["url_in"], 
    args["url_out"], 
    upgrade=args["upgrade"]
)

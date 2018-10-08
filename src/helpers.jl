#############################################################################
# Copyright (C) 2017 - 2018  Spine Project
#
# This file is part of Spine Model.
#
# Spine Model is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#############################################################################


"""
    @suppress_err expr
Suppress the STDERR stream for the given expression.
"""
# NOTE: Borrowed from Suppressor.jl
macro suppress_err(block)
    quote
        if ccall(:jl_generating_output, Cint, ()) == 0
            ORIGINAL_STDERR = STDERR
            err_rd, err_wr = redirect_stderr()
            err_reader = @schedule read(err_rd, String)
        end

        try
            $(esc(block))
        finally
            if ccall(:jl_generating_output, Cint, ()) == 0
                redirect_stderr(ORIGINAL_STDERR)
                close(err_wr)
            end
        end
    end
end


"""
    as_number(str)

An Int64 or Float64 from parsing `str` if possible.
"""
function as_number(str)
    typeof(str) != String && return str
    type_array = [
        Int64,
        Float64,
    ]
    for T in type_array
        try
            return parse(T, str)
        end
    end
    str
end

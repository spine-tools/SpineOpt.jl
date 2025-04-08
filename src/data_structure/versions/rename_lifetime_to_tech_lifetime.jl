#############################################################################
# Copyright (C) 2017 - 2021 Spine project consortium
# Copyright SpineOpt contributors
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
"""
    rename_lifetime_to_tech_lifetime(db_url, log_level)

Replace [xxx]_investment_lifetime by [xxx]_investment_tech_lifetime in all object and relationship class names.
"""
function rename_lifetime_to_tech_lifetime(db_url, log_level)
    @log log_level 0 "Renaming `[xxx]_investment_lifetime` to `[xxx]_investment_tech_lifetime`... "
    pdef = run_request(db_url, "call_method", ("get_item", "parameter_definition"), Dict(
        "entity_class_name" => "connection", "name" => "connection_investment_lifetime")
    )
    if length(pdef) > 0
        run_request(db_url, "call_method", ("update_item", "parameter_definition"), Dict(
            "id" => pdef["id"], "name" => "connection_investment_tech_lifetime")
        )
    end
    pdef = run_request(db_url, "call_method", ("get_item", "parameter_definition"), Dict(
        "entity_class_name" => "node", "name" => "storage_investment_lifetime")
    )
    if length(pdef) > 0
        run_request(db_url, "call_method", ("update_item", "parameter_definition"), Dict(
            "id" => pdef["id"], "name" => "storage_investment_tech_lifetime")
        )
    end
    pdef = run_request(db_url, "call_method", ("get_item", "parameter_definition"), Dict(
        "entity_class_name" => "unit", "name" => "unit_investment_lifetime")
    )
    if length(pdef) > 0
        run_request(db_url, "call_method", ("update_item", "parameter_definition"), Dict(
            "id" => pdef["id"], "name" => "unit_investment_tech_lifetime")
        )
    end
    true
end
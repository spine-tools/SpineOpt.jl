# Update all JSON files in this folder, inclduing
# 1. upgrade the data items to the latest DB version (e.g. renamining, refactoring, etc.)
# 2. amend missing items with respect to the latest SpineOpt template
using JSON
using SpineInterface
using SpineOpt

for path in readdir(@__DIR__; join=true)
    if splitext(path)[end] == ".json"
        @info "upgrading $path"
        data = JSON.parsefile(path, use_mmap=false) 
        # memory mapped files causing issues on windows https://discourse.julialang.org/t/error-when-trying-to-open-a-file/78782
        db_url = "sqlite://"
        SpineInterface.close_connection(db_url)
        SpineInterface.open_connection(db_url)
        import_data(db_url, data, "Import $path")
        # 1. upgrade the data items to the latest DB version
        SpineOpt.upgrade_db(db_url; log_level=3)
        # 2. amend missing items with respect to the latest SpineOpt template
        import_data(db_url, SpineOpt.template(), "Add SpineOpt template")
        new_data = export_data(db_url)
        # parse the value items of the exported DB into Spine Db value types
        #TODO: remove the old terms when we completely switch to the new framework
        for (index, keys) in (
            2 => ("parameter_value_lists",),
            3 => (
                "parameter_definitions", # new terms under the `entity_xx` framework 
                "object_parameters", "relationship_parameters" # old terms
            ),
            4 => (
                "parameter_values", "entity_alternatives", # new terms under the `entity_xx` framework
                "object_parameter_values", "relationship_parameter_values" # old terms
            ),
        )
            for key in keys
                for x in get(new_data, key, ())
                    # replace the corresponding item value in the `new_data` (Dict) with the parsed DB value
                    x[index] = db_value_and_type(parse_db_value(x[index]))
                end
            end
        end
        # write the updated data into the JSON file
        open(path, "w") do f
            JSON.print(f, new_data, 4)
        end
    end
end
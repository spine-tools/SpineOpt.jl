# Upgrades all JSON files in this folder to the latest version
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
        SpineOpt.upgrade_db(db_url; log_level=3)
        new_data = export_data(db_url)
        for (index, keys) in (
            2 => ("parameter_value_lists",),
            3 => ("object_parameters", "relationship_parameters", "parameter_definitions"),
            4 => (
                "object_parameter_values", "relationship_parameter_values", "tool_feature_methods", "parameter_values"
            ),
        )
            for key in keys
                for x in get(new_data, key, ())
                    x[index] = db_value_and_type(parse_db_value(x[index]))
                end
            end
        end
        open(path, "w") do f
            JSON.print(f, new_data, 4)
        end
    end
end
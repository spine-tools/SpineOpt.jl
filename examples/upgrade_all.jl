# Upgrades all JSON files in this folder to the latest version
using JSON
using SpineInterface
using SpineOpt

for path in readdir(@__DIR__; join=true)
    if splitext(path)[end] == ".json"
        @info "upgrading $path"
        data = JSON.parsefile(path)
        db_url = "sqlite://"
        SpineInterface.close_connection(db_url)
        SpineInterface.open_connection(db_url)
        import_data(db_url, data, "Import $path")
        SpineOpt.upgrade_db(db_url; log_level=3)
        new_data = export_data(db_url)
        for key in ("object_parameters", "relationship_parameters")
            for x in get(new_data, key, ())
                x[3] = db_value_and_type(parse_db_value(x[3]))
            end
        end
        for key in ("object_parameter_values", "relationship_parameter_values")
            for x in get(new_data, key, ())
                x[4] = db_value_and_type(parse_db_value(x[4]))
            end
        end
        open(path, "w") do f
            JSON.print(f, new_data, 4)
        end
    end
end
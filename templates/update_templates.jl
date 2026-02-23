# Update all JSON files in the sub-folders, including
# 1. upgrade the data items to the latest DB version (e.g. renamining, refactoring, etc.)
# 2. omit duplicating content with template.
# FIXME: THIS SCRIPT IS NOT GUARANTEED TO WORK PROPERLY!
# WHILE THE TEMPLATES CAN BE MIGRATED, THERE'S NO WAY TO TEST WHETHER THEY WORK!
using SpineOpt

@info "Upgrading templates .jsons..."
for folder in ["archetypes", "models"]
    folderpath = joinpath(@__DIR__, folder)
    for path in readdir(folderpath; join=true)
        if splitext(path)[end] == ".json"
            SpineOpt.upgrade_json(
                path;
                omit_template=true, # Omits duplicate content with template.
                clean_to_latest=true, # Removes content incompatible with latest template.
                version=1, # DO NOT USE UNLESS NECESSARY! # Forces full migration. Unnecessary but serves as a test.
                force=true # DO NOT USE UNLESS NECESSARY! # Forces migration, suppressing some warnings/errors.
            )
        end
    end
end
@info "Done!"

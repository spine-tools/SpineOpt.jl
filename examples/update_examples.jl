# Update all JSON files in this folder, including
# 1. upgrade the data items to the latest DB version (e.g. renamining, refactoring, etc.)
# 2. amend missing items with respect to the latest SpineOpt template
# 3. remove obsolete entries that might be leftover
using SpineOpt

@info "Upgrading example .jsons..."
for path in readdir(@__DIR__; join=true)
    if splitext(path)[end] == ".json"
        SpineOpt.upgrade_json(
            path;
            #version=1, # DO NOT USE! # Run full migration. Unnecessary but serves as a test of the scripts.
            #force=true, # DO NOT USE! # Forces the migration, suppressing some errors/warnings.
            clean_to_latest=true # Removes content incompatible with latest template.
        )
    end
end
@info "Done!"

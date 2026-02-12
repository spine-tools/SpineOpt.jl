# Update all JSON files in this folder, including
# 1. upgrade the data items to the latest DB version (e.g. renamining, refactoring, etc.)
# 2. amend missing items with respect to the latest SpineOpt template
using SpineOpt

@info "Upgrading example .jsons..."
for path in readdir(@__DIR__; join=true)
    if splitext(path)[end] == ".json"
        SpineOpt.upgrade_json(path)
    end
end
@info "Done!"

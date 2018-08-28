function generate_UnitGroups(unitgroup)
        eval(parse(:($unitgroup_unit_rel)))(unitgroup)
end

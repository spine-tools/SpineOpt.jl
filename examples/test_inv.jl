###test_inv
using Revise
using SpineOpt

db_url_in = "sqlite:///$(@__DIR__)\\Data Store 1 - Copy.sqlite"
db_url_out = "sqlite:///$(@__DIR__)\\Data Store 1 - Copy_out.sqlite"
m = run_spineopt(db_url_in, db_url_out)

# testing
SpineOpt.unit_conversion_to_discounted_annuities
SpineOpt.unit_conversion_to_discounted_annuities(unit=unit(Symbol("Wind farm")))
dump(SpineOpt.unit_conversion_to_discounted_annuities(unit=unit(Symbol("Wind farm"))))
SpineOpt.unit_conversion_to_discounted_annuities.classes
SpineOpt.unit_conversion_to_discounted_annuities(unit=unit(Symbol("Wind farm")),stocahstich_scenario=stochastic_scenario(:realization))

using  SpineOpt

db_url_in = "sqlite:///C:/Users/u0111901/Documents/EconomicRepresentation/.spinetoolbox/items/db1/DB1.sqlite"
db_url_out = "sqlite:///C:/Users/u0111901/Documents/EconomicRepresentation/.spinetoolbox/items/db2/DB2.sqlite"
m = run_spineopt(db_url_in, db_url_out; cleanup=false, log_level=2)

# TODO: add the 'second-segment' unit
# TODO: add minimum spillage
# TODO: add penalty for changes somehow

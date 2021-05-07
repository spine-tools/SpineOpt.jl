using SpineOpt

db_url_in = "sqlite:///$(@__DIR__)/data/test_systemA5.sqlite"
db_url_out = "sqlite:///$(@__DIR__)/data/test_systemA5_out.sqlite"
m = run_spineopt(db_url_in, db_url_out; cleanup=false, log_level=2)

# TODO: add the 'second-segment' unit
# TODO: add minimum spillage
# TODO: add penalty for changes somehow

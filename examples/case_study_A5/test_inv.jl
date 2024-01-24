###test_inv
using Revise
using SpineOpt

db_url_in = "sqlite:///Data Store 1 - Copy.sqlite"
db_url_out = "sqlite:///Data Store 1 - Copy_out.sqlite"
m = run_spineopt(db_url_in, db_url_out)

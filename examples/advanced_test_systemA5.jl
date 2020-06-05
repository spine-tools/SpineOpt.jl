using Dates
using SpineInterface
using SpineOpt
import SpineInterface: ScalarDuration

db_url_in = "sqlite:///$(@__DIR__)/data/test_systemA5.sqlite"
db_url_out = "sqlite:///$(@__DIR__)/data/test_systemA5_out.sqlite"
m = run_spinemodel(db_url_in, db_url_out; cleanup=false, log_level=2)

some_week = temporal_block(:some_week)

# Vary resolution from 1 to 24 hours and rerun
for h in 1:24
	temporal_block.parameter_values[some_week][:resolution] = callable(
		db_api.from_database("""{"type": "duration", "data": "$(h) hours"}""")
	)
	m = rerun_spinemodel(db_url_out; cleanup=false, log_level=1)
end

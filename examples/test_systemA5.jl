using Revise
using SpineModel
using SpineInterface
using JuMP
using Cbc

db_url_in = "sqlite:////home/manuelma/Codes/spine/toolbox/projects/case_study_a5/input/input.sqlite"
db_url_out = "sqlite:////home/manuelma/Codes/spine/toolbox/projects/case_study_a5/output/output.sqlite"
m = run_spinemodel(db_url_in, db_url_out; result_name="testing", cleanup=false)

# TODO: add the 'second-segment' unit
# TODO: add minimum spillage
# TODO: add penalty for changes somehow

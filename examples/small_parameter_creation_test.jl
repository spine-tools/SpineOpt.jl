#small test of creating a parameter
map_indices = start.(time_slice(m)[1:2]) ###these are DateTime values
timeseries_array = [TimeSeries(start.(time_slice(m)[1:2]),[3,4],false,false),TimeSeries(start.(time_slice(m)[1:2]),[5,7],false,false)]
#indices = TimeSeries(time_slice(m))
unit.parameter_values[unit()[1]][:CPT_testtinggg] = parameter_value(Map(map_indices,timeseries_array))
CPT_testtinggg = Parameter(:CPT_testtinggg, [unit])
@eval begin
    CPT_testtinggg = $CPT_testtinggg
end

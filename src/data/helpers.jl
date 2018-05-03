function is_excel(dsn::ODBC.DSN)
    dsns = ODBC.dsns()
    i = findfirst(dsn.dsn .== dsns[:,1])
    contains(lowercase(dsns[i,2]), "excel")
end

is_excel_on_windows(dsn::ODBC.DSN) = @static is_windows()?is_excel(dsn):false

compose_table_name(dsn::ODBC.DSN, tbl::String) = is_excel_on_windows(dsn)?string("[", tbl, "\$]"):tbl

# Importing time series from Excel

This tutorial shows how to import time series from an Excel file into a SpineOpt input database with the *Importer* of Spine Toolbox. As an example, we use the hydropower model of [How to model hydropower coupling](@ref) and import its inflows and electricity prices from Excel.

Entering time series by hand in the Spine DB editor works for a few values, but real models usually get their time series from files. The Importer reads the file every time the workflow is run, so when you change the data in Excel and run the workflow again, the input database is updated automatically.

## Overview

In this tutorial we will:
+ start from the basic hydropower model,
+ add the Excel file to the workflow with a *Data Connection*,
+ define in an *Importer* how the Excel sheets map to SpineOpt parameters,
+ and run the workflow, which imports the time series and runs SpineOpt.

The finished workflow looks like this: Data Connection → Importer → input database → Run SpineOpt → output database.

## Starting point

1. Create a workflow in Spine Toolbox with an input database, a Run SpineOpt tool and an output database, as on the [Verify installation](@ref recommended_workflow) page.
2. Double-click the input database to open it in the Spine DB editor.
3. Select **File > Import...** and import the example file [hydro\_power\_coupling.json](https://github.com/spine-tools/SpineOpt.jl/blob/master/examples/hydro_power_coupling.json). It contains the basic model of [How to model hydropower coupling](@ref).
4. Remove the values that we will import from Excel. This way you can be sure that the model uses the imported data: if the import fails, the model has no inflows or prices and gives no solution or different results, instead of silently using the old values.
    - In the Entity tree, select the [node](@ref) class. In the Parameter value table, select the [demand](@ref) rows of *sprang\_upper* and *fall\_upper*, right-click and select **Remove row(s)**.
    - In the Entity tree, select the [node\_\_to\_unit](@ref) class. Select the [vom\_cost](@ref) row of *electricity ǀ electricity\_load*, right-click and select **Remove row(s)**.
5. Press **Commit** in the toolbar.

## The Excel file

Download [hydro\_time\_series.xlsx](https://github.com/spine-tools/SpineOpt.jl/blob/master/examples/hydro_time_series.xlsx) with the **Download raw file** button. It has two sheets:

*inflows*: the local inflows of the reservoirs. In SpineOpt, an inflow is a negative [demand](@ref) of the node.

| time | sprang\_upper | fall\_upper |
|:---|---:|---:|
| 2000-01-01 00:00 | -112 | -2 |
| 2000-01-01 06:00 | -112 | -2 |
| 2000-01-01 12:00 | -112 | -2 |
| 2000-01-01 18:00 | -112 | -2 |

*prices*: the electricity price, which the model uses as a negative [vom\_cost](@ref) of the flow from the *electricity* node to the *electricity\_load* unit.

| time | electricity\_price |
|:---|---:|
| 2000-01-01 00:00 | -325 |
| 2000-01-01 06:00 | -250 |
| 2000-01-01 12:00 | -425 |
| 2000-01-01 18:00 | -400 |

The values are the same as in the example file, so the results will be the same as in [How to model hydropower coupling](@ref). The difference is that the inflows are now time series, so you can give a different value for each time step.

Note the two layouts: in *inflows*, each column is one node, while in *prices* there is only one value column. We will map them in different ways.

## Adding the Excel file to the workflow

1. Drag a **Data Connection** from the toolbar to the *Design View* and name it, e.g. `excel`.
2. In the *Data Connection Properties*, click **+** next to **File paths** and select the downloaded `hydro_time_series.xlsx`.
3. Drag an **Importer** from the toolbar to the *Design View*.
4. Connect the Data Connection to the Importer and the Importer to the input database.
5. In the *Importer Properties*, select **Replace** for values that already exist. Then the Importer updates the values in the input database each time the workflow is run.

The Importer Properties show a warning that the Importer has no specification. The specification defines how the data is mapped to the database, and we create it next.

## Creating the Importer specification

1. Double-click the Importer. The *Importer specification editor* opens and asks for the input type. Select **Excel** and press **OK**.
2. Enter a name for the specification, e.g. `hydro_time_series`, in the **Name** field at the top. The specification can't be saved without a name.

The tables on the left are the sheets of the Excel file. Each table has its own options and mappings.

### Inflows

1. Select the table **inflows**.
2. Check **Has header**. It is on the same row as *Max rows* and *Skip rows*; if you don't see it, widen the window or scroll the row to the right. The first row then becomes the column headers.
3. In the preview, check that the *time* column has the datetime type and the other columns the float type. The type is shown by the button in each column header, and Spine Toolbox usually detects it from the Excel file.
4. Set the options of *Mapping 1*:

| option | value |
|:---|:---|
| Item type | Entity class |
| Parameter type | Value |
| Value | Time series |
| Number of dimensions | 0 |

5. Set the targets. For a *Constant*, double-click the *Source ref.* cell and type the value:

| target | source type | source ref. |
|:---|:---|:---|
| Entity class names | Constant | node |
| Entity names | Headers | |
| Alternative names | Constant | Base |
| Parameter names | Constant | demand |
| Parameter index names | None | |
| Parameter indexes | Column | 1 |
| Parameter values | Pivoted | |

With *Entity names* from the *Headers*, each column header becomes a node, and the values below it become the time series of that node. This is called a pivoted table. The *time* column is used for the *Parameter indexes*, i.e. the time stamps, so it is not imported as a node, although the preview shows its header in the same color as the node names.

### Prices

1. Select the table **prices** and check **Has header** again. Without it, the Importer tries to read the header row as data and gets stuck.
2. Set the options of *Mapping 1*:

| option | value |
|:---|:---|
| Item type | Entity class |
| Parameter type | Value |
| Value | Time series |
| Number of dimensions | 2 |

3. Set the targets:

| target | source type | source ref. |
|:---|:---|:---|
| Entity class names | Constant | node\_\_to\_unit |
| Dimension names 1 | Constant | node |
| Dimension names 2 | Constant | unit |
| Element names 1 | Constant | electricity |
| Element names 2 | Constant | electricity\_load |
| Alternative names | Constant | Base |
| Parameter names | Constant | vom\_cost |
| Parameter index names | None | |
| Parameter indexes | Column | 1 |
| Parameter values | Column | 2 |

The number of dimensions is the number of entities that the entity consists of, not the number of time series. The [vom\_cost](@ref) is a parameter of the [node\_\_to\_unit](@ref) entity *electricity ǀ electricity\_load*, which has two dimensions: the node and the unit. Here the table is not pivoted: the time stamps come from column 1 and the values from column 2.

4. Press **Ctrl+S** to save the specification and close the editor. The warning in the Importer Properties disappears.

## Running the workflow

Press **Project** in the *Execute* section of the toolbar. The Importer runs first, and the *Event Log* shows for each table something like:

```
Processing table inflows
* Applying mapping Mapping 1...
Successful (7 data to be written).
```

Then SpineOpt runs with the imported data.

To check the import, open the input database. The [demand](@ref) of *sprang\_upper* and *fall\_upper* and the [vom\_cost](@ref) of *electricity ǀ electricity\_load* are now shown as *Time series*. Right-click a value and select **Edit...** to see the time stamps and values from the Excel file.

The results are the same as in the basic model of [How to model hydropower coupling](@ref). See *Examining the results* there for how to view them and what you should get.

## Changing the data

Now try changing the data in Excel, e.g. the price of the second time step, save the file and run the workflow again. The Importer replaces the time series in the input database, and SpineOpt uses the new values. You don't need to touch the input database yourself.

More information on the Importer, e.g. other input types and mapping options, is in the [Spine Toolbox documentation](https://spine-toolbox.readthedocs.io/en/latest/data_import_export.html).

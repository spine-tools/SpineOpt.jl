# Simple System tutorial

Welcome to Spine Toolbox's Simple System tutorial.

This tutorial provides a step-by-step guide to setup a simple energy
system on Spine Toolbox and is organized as follows:

<div class="contents" local="">

</div>

## Introduction

### Model assumptions

-   Two power plants take fuel from a source node and release
    electricity to another node in order to supply a demand.
-   Power plant 'a' has a capacity of 100 MWh, a variable operating cost
    of 25 euro/fuel unit, and generates 0.7 MWh of electricity per unit
    of fuel.
-   Power plant 'b' has a capacity of 200 MWh, a variable operating cost
    of 50 euro/fuel unit, and generates 0.8 MWh of electricity per unit
    of fuel.
-   The demand at the electricity node is 150 MWh.
-   The fuel node is able to provide infinite energy.

<img src="img/simple_system_schematic.png" class="align-center"
alt="image" />

### Installation and upgrades

If you haven't yet installed the tools yet, please follow the installation guides: 
- For Spine Toolbox: https://github.com/spine-tools/SpineOpt.jl#installation
- For SpineOpt: https://github.com/spine-tools/Spine-Toolbox#installation

If you are not sure whether you have the latest version, please upgrade to ensure compatibility with this guide.
- For Spine Toolbox: 
- For SpineOpt: https://github.com/spine-tools/SpineOpt.jl#upgrading

## Guide

### Entering input data

#### Importing the SpineOpt database template

1.  Download [the SpineOpt database
    template](https://raw.githubusercontent.com/spine-tools/SpineOpt.jl/master/templates/spineopt_template.json)
    and [the basic SpineOpt
    model](https://raw.githubusercontent.com/spine-tools/SpineOpt.jl/master/templates/models/basic_model_template.json)
    (right click on the links, then select *Save link as...*)

2.  Select the 'input' Data Store item in the *Design View*.

3.  Go to *Data Store Properties* and hit **Open editor**. This will
    open the newly created database in the *Spine DB editor*, looking
    similar to this:

    <img src="img/case_study_a5_spine_db_editor_empty.png"
    class="align-center" alt="image" />

    <div class="note">

    <div class="title">

    Note

    </div>

    The *Spine DB editor* is a dedicated interface within Spine Toolbox
    for visualizing and managing Spine databases.

    </div>

4.  Press **Alt + F** to display the main menu, select **File -\>
    Import...**, and then select the template file you previously
    downloaded (<span class="title-ref">spineopt_template.json</span>).
    The contents of that file will be imported into the current
    database, and you should then see classes like ‘commodity’,
    ‘connection’ and ‘model’ under the root node in the *Object tree*
    (on the left). Then import the second file (<span
    class="title-ref">basic_model_template.json</span>).

5.  From the main menu, select **Session -\> Commit**. Enter ‘Import
    SpineOpt template’ as message in the popup dialog, and click
    **Commit**.

<div class="note">

<div class="title">

Note

</div>

The SpineOpt basic template contains (i) the fundamental entity classes
and parameter definitions that SpineOpt recognizes and expects; and (ii)
some predefined entities for a common deterministic model with a 'flat'
temporal structure.

</div>

#### Creating objects

1.  Always in the Spine DB editor, locate the *Object tree* (typically
    at the top-left). Expand the <span class="title-ref">root</span>
    element if not expanded.

2.  Right click on the <span class="title-ref">node</span> class, and
    select *Add objects* from the context menu. The *Add objects* dialog
    will pop up.

3.  Enter the names for the system nodes as seen in the image below,
    then press *Ok*. This will create two objects of class <span
    class="title-ref">node</span>, called <span
    class="title-ref">fuel_node</span> and <span
    class="title-ref">electricity_node</span>.

    <img src="img/simple_system_add_nodes.png" class="align-center"
    alt="image" />

4.  Right click on the <span class="title-ref">unit</span> class, and
    select *Add objects* from the context menu. The *Add objects* dialog
    will pop up.

<div class="note">

<div class="title">

Note

</div>

In SpineOpt, nodes are points where an energy balance takes place,
whereas units are energy conversion devices that can take energy from
nodes, and release energy to nodes.

</div>

1.  Enter the names for the system units as seen in the image below,
    then press *Ok*. This will create two objects of class <span
    class="title-ref">unit</span>, called <span
    class="title-ref">power_plant_a</span> and <span
    class="title-ref">power_plant_b</span>.

    <img src="img/simple_system_add_units.png" class="align-center"
    alt="image" />

<div class="note">

<div class="title">

Note

</div>

To modify an object after you enter it, right click on it and select
**Edit...** from the context menu.

</div>

#### Establishing relationships

1.  Always in the Spine DB editor, locate the *Relationship tree*
    (typically at the bottom-left). Expand the <span
    class="title-ref">root</span> element if not expanded.

2.  Right click on the <span class="title-ref">unit\_\_from_node</span>
    class, and select *Add relationships* from the context menu. The
    *Add relationships* dialog will pop up.

3.  Select the names of the two units and their **sending** nodes, as
    seen in the image below; then press *Ok*. This will establish that
    both <span class="title-ref">power_plant_a</span> and <span
    class="title-ref">power_plant_b</span> take energy from the <span
    class="title-ref">fuel_node</span>.

    <img src="img/simple_system_add_unit__from_node_relationships.png"
    class="align-center" alt="image" />

4.  Right click on the <span class="title-ref">unit\_\_to_node</span>
    class, and select *Add relationships* from the context menu. The
    *Add relationships* dialog will pop up.

5.  Select the names of the two units and their **receiving** nodes, as
    seen in the image below; then press *Ok*. This will establish that
    both <span class="title-ref">power_plant_a</span> and <span
    class="title-ref">power_plant_b</span> release energy into the <span
    class="title-ref">electricity_node</span>.

    <img src="img/simple_system_add_unit__to_node_relationships.png"
    class="align-center" alt="image" />

6.  Right click on the <span class="title-ref">report\_\_output</span>
    class, and select *Add relationships* from the context menu. The
    *Add relationships* dialog will pop up.

7.  Enter <span class="title-ref">report1</span> under *report*, and
    <span class="title-ref">unit_flow</span> under *output*, as seen in
    the image below; then press *Ok*. This will tell SpineOpt to write
    the value of the <span class="title-ref">unit_flow</span>
    optimization variable to the output database, as part of <span
    class="title-ref">report1</span>.

    <img src="img/simple_system_add_report__output_relationships.png"
    class="align-center" alt="image" />

<div class="note">

<div class="title">

Note

</div>

In SpineOpt, outputs represent optimization variables that can be
written to the output database as part of a report.

</div>

#### Specifying object parameter values

1.  Back to *Object tree*, expand the <span
    class="title-ref">node</span> class and select <span
    class="title-ref">electricity_node</span>.

2.  Locate the *Object parameter* table (typically at the top-center).

3.  In the *Object parameter* table (typically at the top-center),
    select the <span class="title-ref">demand</span> parameter and the
    <span class="title-ref">Base</span> alternative, and enter the value
    <span class="title-ref">100</span> as seen in the image below. This
    will establish that there's a demand of '100' at the electricity
    node.

    <img src="img/simple_system_electricity_demand.png" class="align-center"
    alt="image" />

4.  Select <span class="title-ref">fuel_node</span> in the *Object
    tree*.

5.  In the *Object parameter* table, select the <span
    class="title-ref">balance_type</span> parameter and the <span
    class="title-ref">Base</span> alternative, and enter the value <span
    class="title-ref">balance_type_none</span> as seen in the image
    below. This will establish that the fuel node is not balanced, and
    thus provide as much fuel as needed.

    <img src="img/simple_system_fuel_balance_type.png" class="align-center"
    alt="image" />

#### Specifying relationship parameter values

1.  In *Relationship tree*, expand the <span
    class="title-ref">unit\_\_from_node</span> class and select <span
    class="title-ref">power_plant_a \| fuel_node</span>.

2.  In the *Relationship parameter* table (typically at the
    bottom-center), select the <span class="title-ref">vom_cost</span>
    parameter and the <span class="title-ref">Base</span> alternative,
    and enter the value <span class="title-ref">25</span> as seen in the
    image below. This will set the operating cost for <span
    class="title-ref">power_plant_a</span>.

    <img src="img/simple_system_power_plant_a_vom_cost.png"
    class="align-center" alt="image" />

3.  Select <span class="title-ref">power_plant_b \| fuel_node</span> in
    the *Relationship tree*.

4.  In the *Relationship parameter* table, select the <span
    class="title-ref">vom_cost</span> parameter and the <span
    class="title-ref">Base</span> alternative, and enter the value <span
    class="title-ref">50</span> as seen in the image below. This will
    set the operating cost for <span
    class="title-ref">power_plant_b</span>.

    <img src="img/simple_system_power_plant_b_vom_cost.png"
    class="align-center" alt="image" />

5.  In *Relationship tree*, expand the <span
    class="title-ref">unit\_\_to_node</span> class and select <span
    class="title-ref">power_plant_a \| electricity_node</span>.

6.  In the *Relationship parameter* table, select the <span
    class="title-ref">unit_capacity</span> parameter and the <span
    class="title-ref">Base</span> alternative, and enter the value <span
    class="title-ref">100</span> as seen in the image below. This will
    set the capacity for <span class="title-ref">power_plant_a</span>.

    <img src="img/simple_system_power_plant_a_capacity.png"
    class="align-center" alt="image" />

7.  Select <span class="title-ref">power_plant_b \|
    electricity_node</span> in the *Relationship tree*.

8.  In the *Relationship parameter* table, select the <span
    class="title-ref">unit_capacity</span> parameter and the <span
    class="title-ref">Base</span> alternative, and enter the value <span
    class="title-ref">200</span> as seen in the image below. This will
    set the capacity for <span class="title-ref">power_plant_b</span>.

    <img src="img/simple_system_power_plant_b_capacity.png"
    class="align-center" alt="image" />

9.  In *Relationship tree*, select the <span
    class="title-ref">unit\_\_node\_\_node</span> class, and come back
    to the *Relationship parameter* table.

10. In the *Relationship parameter* table, select <span
    class="title-ref">power_plant_a \| electricity_node \|
    fuel_node</span> under *object name list*, <span
    class="title-ref">fix_ratio_out_in_unit_flow</span> under *parameter
    name*, <span class="title-ref">Base</span> under *alternative name*,
    and enter <span class="title-ref">0.7</span> under *value*. Repeat
    the operation for <span class="title-ref">power_plant_b</span>, but
    this time enter <span class="title-ref">0.8</span> under *value*.
    This will set the conversion ratio from fuel to electricity for
    <span class="title-ref">power_plant_a</span> and <span
    class="title-ref">power_plant_b</span> to <span
    class="title-ref">0.7</span> and <span class="title-ref">0.8</span>,
    respectively. It should like the image below.

    <img src="img/simple_system_fix_ratio_out_in_unit_flow.png"
    class="align-center" alt="image" />

When you're ready, commit all changes to the database.

### Executing the workflow

1.  Go back to Spine Toolbox's main window, and hit the **Execute
    project** button <img
    src="../../spinetoolbox/ui/resources/menu_icons/play-circle-solid.svg"
    width="16" alt="execute_project" /> from the tool bar.

    You should see ‘Executing All Directed Acyclic Graphs’ printed in
    the *Event log* (at the bottom left by default).

2.  Select the 'Run SpineOpt 1' Tool. You should see the output from
    SpineOpt in the *Julia Console*.

### Examining the results

1.  Select the output data store and open the Spine DB editor.
2.  Press **Alt + F** to display the main menu, and select **Pivot -\>
    Index**.
3.  Select <span
    class="title-ref">report\_\_unit\_\_node\_\_direction\_\_stochastic_scenario</span>
    under **Relationship tree**, and the first cell under
    **alternative** in the *Frozen table*.
4.  Under alternative in the Frozen table, you can choose results from
    different runs. Pick the run you want to view. If the workflow has
    been run several times, the most recent run will usually be found at
    the bottom.
5.  The *Pivot table* will be populated with results from the SpineOpt
    run. It will look something like the image below.

<img src="img/simple_system_results_pivot_table.png"
class="align-center" alt="image" />

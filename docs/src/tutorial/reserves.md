# Reserve definition tutorial

This tutorial provides a step-by-step guide to include reserve requirements in a simple energy system with Spine Toolbox for SpineOpt.

## Introduction

Welcome to our tutorial, where we will walk you through the process of adding a new reserve node in SpineOpt using Spine Toolbox. To get the most out of this tutorial, we suggest first completing the Simple System tutorial, which can be found [here](https://spine-tools.github.io/SpineOpt.jl/latest/tutorial/simple_system/).

### Model assumptions

- The reserve node has a requirement of 20MW for upwards reserve
- Power plants 'a' and 'b' can both provide reserve to this node

![image](../figs_reserves/aaa.png)

## Guide

### Entering input data

In this tutorial, you will learn how to add a new reserve node to the Simple System. To begin, please launch the Spine Toolbox and select **File** and then **Open Project** or use the keyboard shortcut **Alt + O** to open the desired project. Afterwards, locate the folder that you saved in the Simple System tutorial and click *Ok*. This will prompt the Simple System workflow to appear in the *Design View* section for you to start working on.

#### Creating objects

- Always in the Spine DB editor, locate the *Object tree* (typically at the top-left). Expand the [root] element if not expanded.
- Right click on the [node] class, and select *Add objects* from the context menu. The *Add objects* dialog will pop up.
- Enter the names for the new reseve node as seen in the image below, then press *Ok*. This will create a new object of class *node*, called *upward\_reserve\_node*.

![image](../figs_reserves/aaa.png)

- Right click on the *node* class, and select *Add object group* from the context menu. The *Add object group* dialog will pop up. In the *Group name* field write *upward\_reserve\_group* to refer to this group. Then, add as a members of the group the nodes *electricity\_node* and *upward\_reserve\_node*, as shown in the image below; then press *Ok*.

!!! note
In SpineOpt, groups of nodes allow the user to create constraints that involve variables from its members. Later in this tutorial, the group named *upward\_reserve\_group* will help to link the flow variables for electricity production and reserve provision.

![image](../figs_reserves/aaa.png)

#### Establishing relationships

- Always in the Spine DB editor, locate the *Relationship tree* (typically at the bottom-left). Expand the *root* element if not expanded.
- Right click on the *unit\_\_to_node* class, and select *Add relationships* from the context menu. The *Add relationships* dialog will pop up.
- Select the names of the two units and their **receiving** nodes, as seen in the image below; then press *Ok*. This will establish that both *power\_plant\_a* and *power\_plant\_b* release energy into the *upward\_reserve\_node*.

![image](../figs_reserves/aaa.png)

- Right click on the *report\_\_output* class, and select *Add relationships* from the context menu. The *Add relationships* dialog will pop up.

- Enter *report1* under *report*, and *variable\_om\_costs* under *output*. Repete the same procedure in the second line to add the *res\_proc\_costs* under *output* as seen in the image below; then press *Ok*. This will write the total *vom\_cost* and *procurement reserve cost* values in the objective function to the output database as a part of *report1*.

![image](../figs_reserves/aaa.png)

#### Specifying object parameter values

- Back to *Object tree*, expand the *node* class and select *upward\_reserve\_node*.
- Locate the *Object parameter* table (typically at the top-center).
- In the *Object parameter* table (typically at the top-center), select the following parameter as seen in the image below:
  - *demand* parameter and the *Base* alternative, and enter the value *20*. This will establish that there's a demand of '20' at the reverse node.
  - *is_reserve_node* parameter and the *Base* alternative, and enter the value *True*. This will establish that it is a reverse node.
  - *upward_reserve* parameter and the *Base* alternative, and enter the value *True*. This will establish the direction of the reserve is upwards.
  - *nodal_balance_sense* parameter and the *Base* alternative, and enter the value $\geq$. This will establish that the total reserve provision must be greater or equal than the reserve demand.

![image](../figs_reserves/aaa.png)

#### Specifying relationship parameter values

- In *Relationship tree*, expand the *unit\_\_to\_node* class and select *power\_plant\_a | upward\_reserve\_node*.

- In the *Relationship parameter* table (typically at the bottom-center), select the *unit\_capacity* parameter and the *Base* alternative, and enter the value *100* as seen in the image below. This will set the capacity to provide reserve for *power\_plant\_a*.

!!! note
The value is equal to the unit capacity defined for the electricity node. However, the value can be lower if the unit cannot provide reserves with its total capacity.

![image](../figs_reserves/aaa.png)

- In *Relationship tree*, expand the *unit\_\_to\_node* class and select *power\_plant\_b | upward\_reserve\_node*.

- In the *Relationship parameter* table (typically at the bottom-center), select the *unit\_capacity* parameter and the *Base* alternative, and enter the value *200* as seen in the image below. This will set the capacity to provide reserve for *power\_plant\_b*.

![image](../figs_reserves/aaa.png)

When you're ready, commit all changes to the database.

### Executing the workflow

TBD

### Examining the results

TBD

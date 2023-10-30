# Ramping definition tutorial

This tutorial provides a step-by-step guide to include ramping constraints in a simple energy system with Spine Toolbox for SpineOpt.

## Introduction

Welcome to our tutorial, where we will walk you through the process of adding ramping constraints in SpineOpt using Spine Toolbox. To get the most out of this tutorial, we suggest first completing the Simple System tutorial, which can be found [here](https://spine-tools.github.io/SpineOpt.jl/latest/tutorial/simple_system/).

The ramping constraint limit refers to the maximum rate at which a power unit can increase or decrease its output flow over time. These limits are typically put in place to prevent sudden and destabilizing shifts in power units. However, they may also represent any other physical limitations that a unit may have that is related to changes over time in its output flow.

### Model assumptions

- Power plant 'a' has ramp limit of 10%

## Guide

### Entering input data

- Launch the Spine Toolbox and select **File** and then **Open Project** or use the keyboard shortcut **Alt + O** to open the desired project.
- Locate the folder that you saved in the Simple System tutorial and click *Ok*. This will prompt the Simple System workflow to appear in the *Design View* section for you to start working on.
- Select the 'input' Data Store item in the *Design View*.
- Go to *Data Store Properties* and hit **Open editor**. This will open the database in the *Spine DB editor*.

In this tutorial, you will learn how to add ramping constraints to the Simple System.

#### Creating objects

When you're ready, save/commit all changes to the database.

### Executing the workflow

- Go back to Spine Toolbox's main window, and hit the **Execute project** button ![image](figs_simple_system/play-circle.png) from the tool bar. You should see 'Executing All Directed Acyclic Graphs' printed in the *Event log* (at the bottom left by default).

- Select the 'Run SpineOpt' Tool. You should see the output from SpineOpt in the *Julia Console* after clicking the *object activity control*.

### Examining the results

- Select the output data store and open the Spine DB editor. You can already inspect the fields in the displayed tables or use a pivot table.

- For the pivot table, press **Alt + F** for the shortcut to the hamburger menu, and select **Pivot -> Index**.

- Select *report\_\_unit\_\_node\_\_direction\_\_stochastic\_scenario* under **Relationship tree**, and the first cell under **alternative** in the *Frozen table*.

- Under alternative in the Frozen table, you can choose results from different runs. Pick the run you want to view. If the workflow has been run several times, the most recent run will usually be found at the bottom.

- The *Pivot table* will be populated with results from the SpineOpt run. It will look something like the image below.

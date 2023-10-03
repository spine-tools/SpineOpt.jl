# Unit commitment constraints tutorial

This tutorial provides a step-by-step guide to include unit commitment constraints in a simple energy system with Spine Toolbox for SpineOpt.

## Introduction

Welcome to our tutorial, where we will walk you through the process of adding unit commitment constraints in SpineOpt using Spine Toolbox. To get the most out of this tutorial, we suggest first completing the Simple System tutorial, which can be found [here](https://spine-tools.github.io/SpineOpt.jl/latest/tutorial/simple_system/).

### Model assumptions

- TBD
- TBD

## Guide

### Entering input data

In this tutorial, you will learn how to add a new reserve node to the Simple System. To begin, please launch the Spine Toolbox and select **File** and then **Open Project** or use the keyboard shortcut **Alt + O** to open the desired project. Afterwards, locate the folder that you saved in the Simple System tutorial and click *Ok*. This will prompt the Simple System workflow to appear in the *Design View* section for you to start working on.

#### Creating objects

TBD

#### Establishing relationships

TBD

#### Specifying object parameter values

TBD

#### Specifying relationship parameter values

When you're ready, commit all changes to the database.

### Executing the workflow

- Go back to Spine Toolbox's main window, and hit the **Execute project** button ![image](../figs_simple_system/play-circle.png) from the tool bar. You should see 'Executing All Directed Acyclic Graphs' printed in the *Event log* (at the bottom left by default).

- Select the 'Run SpineOpt' Tool. You should see the output from SpineOpt in the *Julia Console* after clicking the *object activity control*.

### Examining the results

- Select the output data store and open the Spine DB editor. You can already inspect the fields in the displayed tables or use a pivot table.

- For the pivot table, press **Alt + F** for the shortcut to the hamburger menu, and select **Pivot -> Index**.

- Select *report\_\_unit\_\_node\_\_direction\_\_stochastic\_scenario* under **Relationship tree**, and the first cell under **alternative** in the *Frozen table*.

- Under alternative in the Frozen table, you can choose results from different runs. Pick the run you want to view. If the workflow has been run several times, the most recent run will usually be found at the bottom.

- The *Pivot table* will be populated with results from the SpineOpt run. It will look something like the image below.

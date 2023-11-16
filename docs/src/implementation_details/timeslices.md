# How does SpineOpt perceive time?

Questions:
1. What are time slices?
2. What are time slices functions?
3. How can they be used?

## From temporal block to time slices

Overview of the process:
1. run_spineopt
    a. create time slices for each of the (model) temporal blocks
    b. create fictitious relationships between time slice objects
    c. store these in m.ext
2. time slice convenience functions
    a. fetch generated relations from m.ext

SpineOpt really starts with the *run_spineopt* function.
One of its main parts is to create the temporal (and stochastic) structure.
The temporal structure starts from the temporal blocks in the input data.
Only the temporal blocks that are connected to a model object are considered.
Time slices are created for each of these temporal blocks.
A time slice is characterised by a start time and an end time.
In other words, the time frame is composed of a bunch of segments,
determined from the resolution of the temporal block
between the model start and end time.
To keep track of the order of the time slices (across temporal blocks??),
SpineOpt then creates a fictitious relationship between time slice objects.
These time slices and their relationships are stored in m.ext.
To later make use of the time slices and their relationships,
there are time slice convenience functions
that fetch the generated slices and relations from m.ext.

!!! note
    m is the model that SpineOpt builds and sends to the JuMP solver.
    m.ext is an additional field where SpineOpt stores some extra stuff.

## What are the time slice convenience functions?

The time slice convenience functions help
with the interaction of time slices in constraints.

!!! note
    If you are looking for the time slice convenience functions in the code,
    you should not look for a typical *function end* structure
    but rather the short hand notation in *f()* format.

!!! note
    To further figure out what the time slice convenience functions do,
    you can play around with these functions.
    To do so, you first need to make a database (e.g. in SpineToolbox).
    Then you can run run_spineopt with that database and collect the model m.
    If you are impatient you do not even need to solve the model
    and set the optimize option to *false*.
    And then you can start with calling the time slice convenience functions with m
    (e.g. t_in_t).

## How can the time slice convenience functions be used?


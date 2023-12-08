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
        i. relationship between two consecutive time slices (t\_before and t\_after)
        ii. relationship between overlapping time slices (t\_short which is in t\_long)
    c. store these in m.ext
2. time slice convenience functions
    a. fetch generated relations from m.ext

SpineOpt starts with the *run_spineopt* function.
One of its main parts is to create the temporal (and stochastic) structure.
The temporal structure starts from the temporal blocks in the input data.
Only the temporal blocks that are connected to a model object are considered.
Time slices are created for each of these temporal blocks.
A time slice is characterised by a start time and an end time.
In other words, the time frame is composed of a bunch of segments,
determined from the resolution of the temporal block
between the model start and end time.

To keep track of the order of the time slices,
SpineOpt then creates a fictitious relationship between time slice objects (across all temporal blocks connected to the model).
There are two types of relationships, i.e. a relationship between consecutive time steps and a relationship between overlapping time steps.

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

The functionality is similar to a dictionary or a lookup table;
for each time slice function and for each time slice
collect all time slices of all temporal blocks combined.

The functions are (with t* the input time slice):

t\_in\_t
+ uses the relationship between t\_short and t\_long
+ if you provide the keyword `short=t*`
you get t\_long in which t\* resides
+ if you provide the keyword `long=t*`
you get t\_short that is contained in t\*

t\_consecutive\_t
+ uses the relationship between t\_before and t\_after
+ if you provide the keyword `t\_before=t*`
you get all the possible t\_after
+ if you provide the keyword `t\_after=t*`
you get all the possible t\_before

t\_overlapping\_t
+ is a dictionary from a time slice to an array of time slices
+ it uses a dictionary instead of a relationship because the operation is symmetric and does not require logic and loops
+ provides all overlapping time slices (including partially overlapping time slices)

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

!!! note
    Older versions of SpineOpt use t\_before\_t instead of t\_consecutive\_t but that naming has changed because it is rather confusing.

    There was also a variation on the time slicing functions with \_excl which excludes t* from the returned time slices. That functionality was scrapped because it was not used.

## How can the time slice convenience functions be used?

When designing a constraint in SpineOpt, you should determine which time slices to use as a reference (which will be obtained from the index function below the constraint). The reference time slice can be used directly in the constraints whereas the other time slices (for each variable and parameter) need to be determined from the reference using the time slicing functions.

A fool proof way of designing the constraint is to always consider the highest resolution among the overlapping time slices as the reference time slice. The other time slices can then be obtained from t\_overlapping\_t.

More information can be found in the design of constraints.
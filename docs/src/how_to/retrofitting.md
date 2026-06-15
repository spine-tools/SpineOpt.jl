# How to Model Retrofitting

This how-to introduces how we can model retrofitting in SpineOpt. The meaning of retrofitting may vary depending on the context and so does the modelling approach. Here we focus on the very fundamental case where one wants to retrofit an existing [unit](@ref) for the continuation of current supply generation. The introduced approach can also model retrofitting an existing [unit](@ref) for producing for a different demand. Same retrofitting processes for [connection](@ref) and [node](@ref) storage can be modelled likewise.

## Model Setup

This section briefs the model instance setup with illustrating the key system specification. The file [retrofitting_example_1.json](./retrofit_material/retrofitting_example_1.json) provides a complete database of this example model instance.

### Basic System Instance Setup

The base system consists of 
- a [node](@ref) "demand_A" with a fixed energy [demand](@ref) of 100 over the entire modelling horizon
- an existing [unit](@ref) "generator_A" to supply "demand_A" with [capacity\_per\_unit](@ref)="100" and [vom\_cost](@ref)="2". This unit, however, will retire as of hour 5, specified by the 'Time series' value of parameter [investment\_count\_fix\_cumulative](@ref).
- an investable [unit](@ref) "generator_A_new" of the same techno-economic characteristics as "generator_A", with [unit\_investment\_cost](@ref)="1000" and a 15-year [lifetime\_technical](@ref). This unit represents the as-usual replacement of "generator_A" when it gets retired.

![Basic system setup.](./retrofit_material/example_1_system_basic.png)

### Retrofitting Setup

For retrofitting, we introduce a new [unit](@ref) "generator_A_retro" as an alternative investment option of "generator_A_new", with the same [vom\_cost](@ref) and [lifetime\_technical](@ref), and different [capacity\_per\_unit](@ref)="80" and [unit\_investment\_cost](@ref)="400". In this configuration, we would model the case where 80% of "generator_A"'s capacity can be retrofitted in a cheaper investment cost than building a new one.

Particularly, the last and key steps to make "generator_A_retro" a retrofitting option for "generator_A" include:
1. create an [investment\_group](@ref) entity "retrofitting", and connect it to "generator_A" and "generator_A_retro",
2. define the parameter [investment\_count\_total\_max\_cumulative](@ref)="1".

![Configuration of retrofitting unit](./retrofit_material/example_1_system_retrofit_unit.png)

This way, "generator_A_retro" can only be invested in if "generator_A" is retired.

### Model Structure

For simplicity, the example model spans 20 hour with an hourly resolution for both operations and investment. Investment decisions are modelled as continuous value by defining the parameter [investment\_variable\_type](@ref) = `linear`.

The complete model configuration is provided below:
![Complete model specification](./retrofit_material/example_1_system_complete.png)

## Model Results

As expected, as of hour 5 when "generator_A" retires, the model invests in all capacity=80 of "generator_A_retro" to continue supplying "demand_A", and in capacity=20 new installation "generator_A_new" for the residue demand. The results are illustrated below:

### Investment Related Variables
![Plot for units_invested](./retrofit_material/example_1_results_units_invested.png)
![Plot for units_invested_available](./retrofit_material/example_1_results_invested_available.png)

### Operation Related Variables
![Plot for unit_flow](./retrofit_material/example_1_results_unit_flow.png)
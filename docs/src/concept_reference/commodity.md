## `commodity`

AN EXAMPLE FOR HOW THE AUTOGENERATION OF `CONCEPT REFERENCE` BASED ON SPINEOPT TEMPLATE WORKS

A `commodity` refers to any product that can be produced, consumed, transported, traded, etc.

References to other sections, e.g. [node](@ref) are handled like this.
Don't use the grave accents around the reference name, as it seems to break the reference!
Self-references, like [commodity](@ref) don't seem to work either, unfortunately.
I don't know if it would be possible to automatically parse a list of related `relationship_classes`, `parameters`, etc.
based on the `spineopt_template.json` and automatically add it at the end or something, but that would be pretty cool.
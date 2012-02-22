
This module defines a language for packaging objects and code using a dependency tree.
Currently it is primarily used to group schemas, grammars, stencils and interpreters together into features.

Usage:
'load' -- saves a feature into the Loader
web-base -- looks for: a variable named 'web-base', a feature file 'web-base.feature', or the .schema and .grammar files for web-base, in that order
"web-base.schema" -- looks for the file 'web-base.schema', and produces a feature containing this one artefact
compose (.) -- left to right union
rename (S [a->b]) -- renames a to b in S, behavior differ depending on the type of S

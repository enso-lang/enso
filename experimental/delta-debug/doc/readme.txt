Delta Debugging for Enso
------------------------

1. Motivation
The conventional approach of state inspection at execution breakpoints is not well suited for specification languages like those created by Enso. Application programmers coding in specification languages should not be required to understand the underlying execution model sufficiently to know where the critical breakpoints are. Nor is the program state, which can contain huge amounts of generated and temporary data in addition to the pertinent models, necessarily helpful to them.

A classic example of such a specification language would be SQL; its execution model, the query optimizer, elides the actual sequence of operations and its huge intermediate states are not amenable to manual inspection.

A more appropriate approach should instead directly link the errors in the observable program output to the errant subsections of the program source.

One possible implementation for such an approach would use delta debugging [Zeller99]. Another implementation might be its corollary of tainting [Dhoolia10]. Delta debugging accepts two program sources and a test function that returns a different result for them, and applies a blackbox approach to isolate the smallest delta between these sources that causes difference in the test function.


2. Implementation

This experimental module implements delta debugging for Enso programs. Given two object graphs and a 'test case' that returns a different boolean result for each of them, determine the "smallest" delta that would result in the change. The test case would typically be the combination of the normal interpreter for these programs as well as a failing test case.

An example is given in test_dd.rb.


[Zeller99] Zeller, Yesterday, my program worked. Today, it does not. Why?, ESEC/FSE '99
[Dhoolia10] Pankaj Dhoolia, Senthil Mani, V Sinha, Saurabh Sinha, Debugging Model-Transformation Failures Using Dynamic Tainting, ECOOP '10


NOTES:
Challenges:
- Abstraction level gap between DSL specification and output
- Declarative DSLs without control-flow-based operational semantics
Possible solns:
1. fully blackbox style, ie "test-driven", ala delta debugging, slicing, etc
2. event signalling? eg by weaving into the interpreter. the app programmer can do this!

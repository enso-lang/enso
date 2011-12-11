// set unification?, object unification
// in reverse, may get a thing with free/logic variables

graph(Schema {types: Types; classes: Classes}, 
        Graph {nodes: Nodes; edges: Edges}) :-
  // for each type/classes
  node(Types, Nodes),
  edges(Classes, Edges).

node(Primitive {name: Name}, Node {name: Name; shape: "plain"}).
node(Class {name: Name, _}, Node {name: Name; shape: "box"}).

edges(Class {defined_fields: Fs}, Edges) :-
  edge(Fs, Edges).

edge(Field {name: Name; owner: Class; type: Type},
      Edge {label: Name, from: N1, to: N2}) :-
    node(owner, N1),
    node(type, N2).

edge'(Field {name: update(Name, Name'); owner: Class; type: Type},
      Edge {label: update(Name, Name'), from: N1, to: N2}) :-
    node(owner, N1),
    node(type, N2).
      

:- graph(aSchema, G)
-> graph

:- graph(S, aGraph)
-> schema (???) a minimal schema that satisfies the rules.
this can then be unioned with the original schema??

:- graph(aSchema, aGraph)
-> yes/no

:- graph(aSchema, anUpdatedGraph)
an updated schema?


  
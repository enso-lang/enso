Getting started with Enso
=========================
This project contains Ensō, a theoretically sound and practical reformulation 
of the concepts of model-driven software development.

See http://enso-lang.org for more information.



1) Installation
---------------
Main Enso requires no installation but individual modules might have outside
dependencies. There is a makefile for Javascript translation. It is not used 
for normal Enso operation.

You need:
 - Ruby 1.9.3 (fully tested with 2.1.0)
 - json gem (required!)
 - test-unit gem (required!)

You may need:
 - bigdecimal gem
 - colored gem (for debugger)
 - rake (for web)
 - Electron (for new stencil)

You may want (only if you know you do):
 - Eclipse IDE. Suggested configuration files are kept in git.
 - Rascal. There is an Enso plugin for Rascal.

2) How to run Enso
------------------

a) cd to {ENSO_HOME}/src

b) Run: ruby -I. {SOME RUBY FILE}

  eg. ruby -I. core/expr/eval.rb

You can add the following to your .bashrc to avoid the -I switch:

  export RUBYOPT="-I {ENSO_HOME}/src"

There are several commonly used utility functions in the /bin directory. These
are all aliases to existing Ruby files.

3) Running the demos
--------------------
Refer to README in individual sample for running instructions.

* bin/render.sh <ModelName>
    where ModelName is any model in the system. Examples include:
      schema.schema grammar.grammar schema.grammar grammar.schema
      stencil.schema state_machine.schema door.state_machine
      grades.schema 
      
* Run GUI applications
    a)  cd js
    b)  {path-to-electron}Electron .
      
      You can use CMD-O to open/edit many models. Examples include:
		      ../core/schema/models/schema.schema 
		      ../core/grammar/models/grammar.schema
		      ../core/diagram/models/stencil.schema 
		      ../demo/StateMachine/models/state_machine.schema
		      ../demo/StateMachine/test/door.state_machine
 
* demo/StateMachine
Simple state machine example to demonstrate writing a schema, grammar, and 
interpreter.
   ruby -I. demo/StateMachine/tests/example.rb demo/StateMachine/tests/door.state_machine
Then type "open" "close" "lock" each on its own line (without quotes).

* demo/LiveSheet
   Simple replacement for Excel spreadsheats. Still in development.
   ruby -I. demo/LiveSheet/test/test.rb

* [NOT WORKING] demo/Piping
Most complete example from LWC '12. Has schema, grammar and interpreter for a 
water heating simulation system and its state-machine-based controller. Output
is rendered via stencil. Also feature a modular debugger.

* demo/Questionaire
Questionaire language submission for LWC '13. Zero lines of code! Logic is 
completely embedded into stencil (mostly) and grammar/schema.

* core/expr
Basic expression language and evaluator. Features value tracking (tainting) and
functional reactive programming (FRP).
  Two tests that run the examples in core/expr/test
		ruby -I. core/expr/test/test_expr.rb
		ruby -I. core/expr/test/test_impl.rb



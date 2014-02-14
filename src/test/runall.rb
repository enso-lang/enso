
### Tests for Enso basic functionality ###
#  eg Schema, Grammar, Expr, etc
#  (if these don't run, Enso won't start)
require 'core/schema/test/test_copy.rb'
require 'core/schema/test/test_model.rb'
require 'core/grammar/test/parse.rb'
require 'core/expr/test/test_impl.rb'
require 'core/expr/test/test_expr.rb'
require 'test/unit/test_diff.rb'
require 'test/unit/test_patch.rb'


### Core languages ###
#  (failure impacts several other applications)

# Diagram/Stencil

# Debugger


### Applications tests ###
#  (failure is local, but frequently use for demos)

# Piping
require '../demos/Piping/test/simulator.rb'
require '../demos/Piping/test/controller.rb'

# EnsoSync


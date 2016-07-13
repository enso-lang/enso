.SUFFIXES: .rb .js .code .schema .grammar .state_machine

SOURCES = \
	js/core/system/boot/meta_schema.js \
	js/core/system/load/load.js \
	js/core/system/load/cache.js \
	js/core/system/utils/find_model.js \
	js/core/system/utils/paths.js \
	js/core/system/library/schema.js \
	js/core/schema/code/factory.js \
	js/core/schema/code/dynamic.js \
	js/core/schema/tools/dumpjson.js \
	js/core/schema/tools/union.js \
	js/core/schema/tools/print.js \
	js/core/schema/tools/equals.js \
	js/core/semantics/code/interpreter.js \
	js/core/grammar/render/layout.js \
	js/core/grammar/parse/sppf.js \
	js/core/grammar/parse/gss.js \
	js/core/expr/code/impl.js \
	js/core/expr/code/env.js \
	js/core/expr/code/freevar.js \
	js/core/expr/code/eval.js \
	js/core/expr/code/lvalue.js \
	js/core/expr/code/renderexp.js \
	js/core/expr/taint/proxy.js \
	js/core/diagram/code/diagram.js \
	js/core/diagram/code/stencil.js \
	js/core/diagram/code/constraints.js \

MODELS = \
	stencil.grammar \
	expr.grammar \
	impl.grammar \
	myexp.grammar \
	grammar.grammar \
	grammar_BNF.grammar \
	grammar_latex_min.grammar \
	lets.grammar \
	mult.grammar \
	paths.grammar \
	recursion.grammar \
	sequence.grammar \
	unary.grammar \
	code.grammar \
	code_js.grammar \
	schema.stencil \
	state_machine.stencil	\
	genealogy-dot.grammar \
	genealogy.grammar \
	auth.grammar \
	diagram.grammar \
	schema.grammar \
	point.grammar \
	lambda.grammar \
	petstore.grammar \
	controller.grammar \
	piping.grammar \
	ql.grammar \
	state_machine.grammar \
	todo.grammar \
	batch.schema \
	dbext.schema \
	esync.schema \
	genealogy.schema \
	auth.schema \
	content.schema \
	debug-state.schema \
	element.schema \
	web_base.schema \
	xml.schema \
	diagram.schema \
	stencil.schema \
	expr.schema \
	impl.schema \
	myexp.schema \
	grammar-template-base.schema \
	grammar-template.schema \
	template-expression.schema \
	template.schema \
	gll.schema \
	grammar.schema \
  item.schema \
	itemize.schema \
	layout.schema \
	normalize.schema \
	parsing.schema \
	binding.schema \
	lets.schema \
	code.schema \
	schema.schema \
	point.schema \
	lambda.schema \
	petstore.schema \
	controller.schema \
	piping-sim.schema \
	piping.schema \
	ql.schema \
	state_machine.schema \
	door.state_machine \
	
	
JSONS_QL = \
  housing.ql \
  ql.stencil

JSONS_PIPING = \
  boiler.controller \
  boiler.piping \
  piping-sim.schema \

main: $(SOURCES)

check: 
	ruby bin/check_requires.rb `find core | grep ".rb"`

.SECONDARY:

code/%.code: %.rb
	echo "PROCESSING " $< " TO " $@
	mkdir -p `dirname $@`
	ruby -I . core/lang/code/convert.rb $< $@

parse/%.code: %.rb
	echo "PROCESSING " $< " TO " $@
	mkdir -p `dirname $@`
	ruby -I . core/lang/code/convert.rb $< $@

js/%.js: %.rb core/lang/models/code_js.grammar
	echo "GENERATING " $@
	mkdir -p `dirname $@`
	ruby -I . core/lang/code/convert.rb $< $@ code_js

clean-json:
	ruby -I . core/system/load/cache.rb

load-json:
	ruby -I . core/system/load/load.rb $(JSONS_QL) $(JSONS_PIPING)

questionaire: main
	ruby -I . core/system/load/load.rb $(JSONS_QL)
	js/run-web.sh housing.ql

piping: main
	ruby -I . core/system/load/load.rb $(JSONS_PIPING)

buildcache:
	ruby -I . core/system/test/load_test.rb $(MODELS)

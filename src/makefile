.SUFFIXES: .rb .js .code

main: \
	js/core/schema/code/factory.js \
	js/core/system/boot/meta_schema.js \
	js/core/schema/code/many.js \
	js/core/schema/code/dynamic.js \
	js/core/system/utils/paths.js \
	js/core/system/library/schema.js \

foo: \
	core/semantics/code/interpreter.js \
	core/expr/code/impl.js \
	core/expr/code/env.js \
	core/expr/code/freevar.js \

.SECONDARY:

code/%.code: core/src/lang/code/convert.rb core/src/lang/models/code.grammar makefile
code/%.code: %.rb
	echo "PROCESSING " $< " TO " $@
	mkdir -p `dirname $@`
	ruby -I . core/lang/code/convert.rb $< $@
 
js/%.js: core/src/lang/models/code_js.grammar makefile
js/%.js: code/%.code
	echo "GENERATING " $@
	mkdir -p `dirname $@`
	ruby -I . core/grammar/render/trans.rb $< code_js $@



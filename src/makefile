.SUFFIXES: .rb .js .code

main: \
	js/core/schema/code/factory.js \
	js/core/system/boot/meta_schema.js \
	js/core/schema/code/dynamic.js \
	js/core/system/utils/paths.js \
	js/core/system/library/schema.js \
	js/core/semantics/code/interpreter.js \
	js/core/expr/code/impl.js \
	js/core/expr/code/env.js \
	js/core/expr/code/freevar.js \
	js/core/system/load/load.js \
	js/core/expr/code/eval.js \
	js/core/expr/code/lvalue.js \
	js/core/schema/tools/union.js \
	js/core/grammar/render/layout.js \
	js/core/grammar/render/render.js \
	js/core/grammar/parse/sppf.js \
	js/core/grammar/parse/gss.js \
	js/core/system/load/cache.js \
	js/core/system/utils/find_model.js \
  js/core/schema/tools/dumpjson.js \
  js/core/schema/tools/print.js \
  js/core/grammar/parse/topath.js \

foo: \
    js/core/grammar/parse/origins.js \
    js/core/grammar/parse/gll.js \
    js/core/grammar/parse/build.js \



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

#ruby -I . core/grammar/render/trans.rb $< code_js $@



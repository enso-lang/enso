.SUFFIXES: .rb .js .code

main: \
	core/system/boot/meta_schema.js \
	core/schema/code/factory.js \
	core/schema/code/many.js \
	core/schema/code/dynamic.js \
	core/system/utils/paths.js \
	core/system/library/schema.js \
  core/semantics/code/interpreter.js \
  core/expr/code/impl.js \
  core/expr/code/env.js \
  core/expr/code/freevar.js \


foo:
	

.rb.code: 
	echo "PROCESSING " $<
	ruby -I . core/lang/code/convert.rb $<

.code.js:
	echo "GENERATING " $@
	ruby -I . core/grammar/render/trans.rb $< code_js > $@

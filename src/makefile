.SUFFIXES: .rb .js .code .schema .grammar .state_machine


MODELS = \
	fibo.impl \
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
	schema_kt1.grammar \
	schema_kt2.grammar \
	expr_kt.grammar \
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
	todo.schema \
	batch.schema \
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
  prelude.ql \
	housing.ql \
	gll.schema \
	grammar.schema \
  item.schema \
	itemize.schema \
	layout.schema \
	boiler.controller \
	controller.stencil \
	boiler.piping \
  piping.stencil \
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
	grades.schema \
	gradeData.schema \
	gradeData.grammar \
	point1.point \
	point2.point 
	
JSONS_QL = \
  housing.ql \
  ql.web

JSONS_PIPING = \
  boiler.controller \
  boiler.piping \
  piping-sim.schema \

main: rascal2js buildcache 

rascal2js:
	make -f makefile.rascal
	
	
check: 
	ruby bin/check_requires.rb `find core | grep ".rb"`

.SECONDARY:


clean-json:
	rm cache/*
	
load-json:
	ruby -I . core/system/load/load.rb $(JSONS_QL) $(JSONS_PIPING)

questionaire: main
	ruby -I . core/system/load/load.rb $(JSONS_QL)
	html/run-web.sh housing.ql

piping: main
	ruby -I . core/system/load/load.rb $(JSONS_PIPING)

buildcache:
	ruby -I . core/system/test/load_test.rb $(MODELS)

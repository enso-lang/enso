
build:
	bin/render.sh schema.schema schema_kt1 > core/lang/kotlin/schema_schema.kt
	bin/render.sh schema.schema schema_kt2 > core/lang/kotlin/schema_schema_imp.kt

	bin/render.sh stencil.schema schema_kt1 > core/lang/kotlin/stencil_schema.kt
	bin/render.sh stencil.schema schema_kt2 > core/lang/kotlin/stencil_schema_imp.kt

	bin/render.sh grammar.schema schema_kt1 > core/lang/kotlin/grammar_schema.kt
	bin/render.sh grammar.schema schema_kt2 > core/lang/kotlin/grammar_schema_imp.kt

	bin/render.sh state_machine.schema schema_kt1 > core/lang/kotlin/machine_schema.kt
	bin/render.sh state_machine.schema schema_kt2 > core/lang/kotlin/machine_schema_imp.kt

	bin/render.sh expr.schema schema_kt1 > core/lang/kotlin/expr_schema.kt
	bin/render.sh expr.schema schema_kt2 > core/lang/kotlin/expr_schema_imp.kt

	bin/render.sh impl.schema schema_kt1 > core/lang/kotlin/impl_schema.kt
	bin/render.sh impl.schema schema_kt2 > core/lang/kotlin/impl_schema_imp.kt

diff:
	- diff core/lang/kotlin/schema_schema.kt			~/IdeaProjects/Kenso/src/schema/schema_schema.kt
	- diff core/lang/kotlin/schema_schema_imp.kt	~/IdeaProjects/Kenso/src/schema/schema_schema_imp.kt

	- diff core/lang/kotlin/machine_schema.kt		~/IdeaProjects/Kenso/src/state_machine/machine_schema.kt
	- diff core/lang/kotlin/machine_schema_imp.kt	~/IdeaProjects/Kenso/src/state_machine/machine_schema_imp.kt

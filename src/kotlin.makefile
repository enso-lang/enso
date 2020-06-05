
build:
	bin/render.sh schema.schema schema_kt1 > core/lang/kotlin/SchemaSchema.kt
	bin/render.sh schema.schema schema_kt2 > core/lang/kotlin/SchemaSchemaImp.kt

	bin/render.sh state_machine.schema schema_kt1 > core/lang/kotlin/machine.kt
	bin/render.sh state_machine.schema schema_kt2 > core/lang/kotlin/machineImp.kt

diff:
	- diff core/lang/kotlin/SchemaSchema.kt			~/IdeaProjects/Kenso/src/schema/SchemaSchema.kt
	- diff core/lang/kotlin/SchemaSchemaImp.kt	~/IdeaProjects/Kenso/src/schema/SchemaSchemaImp.kt

	- diff core/lang/kotlin/machine.kt		~/IdeaProjects/Kenso/src/state_machine/machine.kt
	- diff core/lang/kotlin/machineImp.kt	~/IdeaProjects/Kenso/src/state_machine/machineImp.kt

function schemaSchema() {
    var ids = 0;
    
    var schemaSchema = {
	    _id: ids++,
	    types: new IdSet(),
	    classes: new IdSet(),
	    primitives: new IdSet(),
	    isManaged: true
    };
    
    var classSchema = {
	    _id: ids++,
	    name: 'Schema',
	    schema: schemaSchema,
	    key: null, // field name
	    supers: new IdSet(),
	    subclasses: new IdSet(),
	    defined_fields: new IdSet(),
	    fields: new IdSet(),
	    all_fields: new IdSet()
    }
    
    var fieldTypes = {
	    _id: ids++,
	    name: 'types',
	    owner: classSchema,
	    type: null, // classType
	    optional: true, 
	    many: true,
	    key: false,
	    inverse: null,
	    computed: null,
	    traversal: true 
    }
    
    var fieldClasses= {
	    _id: ids++,
	    name: 'classes',
	    owner: classSchema,
	    type: null, // classType
	    optional: true, 
	    many: true,
	    key: false,
	    inverse: null,
	    computed: null,
	    traversal: false
    }
    
    var fieldPrimitives = {
	    _id: ids++,
	    name: 'types',
	    owner: classSchema,
	    type: null, // primitveType
	    optional: true, 
	    many: true,
	    key: false,
	    inverse: null,
	    computed: null,
	    traversal: false 
    }
    
    var classType = {
	    _id: ids++,
	    name: 'Type',
	    schema: schemaSchema,
	    key: null, // field name
	    supers: new IdSet(),
	    subclasses: new IdSet(),
	    defined_fields: new IdSet(),
	    fields: new IdSet(),
	    all_fields: new IdSet()
    }
    
    
    
    
    var classPrimitive = {
	    _id: ids++,
	    name: 'Primitive',
	    schema: schemaSchema,
	    key: null, // field name
	    supers: new IdSet(),
	    subclasses: new IdSet(),
	    defined_fields: new IdSet(),
	    fields: new IdSet(),
	    all_fields: new IdSet()
    }
    
    var classClass = {
	    _id: ids++,
	    name: 'Class',
	    schema: schemaSchema,
	    key: null, // field name
	    supers: new IdSet(),
	    subclasses: new IdSet(),
	    defined_fields: new IdSet(),
	    fields: new IdSet(),
	    all_fields: new IdSet()
    };
    
    var classField = {
	    _id: ids++,
	    name: 'Field',
	    schema: schemaSchema,
	    key: null, // field name
	    supers: new IdSet(),
	    subclasses: new IdSet(),
	    defined_fields: new IdSet(),
	    fields: new IdSet(),
	    all_fields: new IdSet()
    }
    
    var primInt = {
	    _id: ids++,
	    name: 'int',
	    schema: schemaSchema,
	    key: null,
	    isManaged: true
    }
    
    var primStr = {
	    _id: ids++,
	    name: 'str',
	    schema: schemaSchema,
	    key: null,
	    isManaged: true
    }
    
    var primBool = {
	    _id: ids++,
	    name: 'bool',
	    schema: schemaSchema,
	    key: null,
	    isManaged: true
    }
    
}

function pointSchema() {
    var schema = {
	    _id: 0,
	    types: new IdSet(),
	    classes: new IdSet(),
	    primitives: new IdSet(),
	    isManaged: true
    };
    
    var primInt = {
	    _id: 1,
	    name: 'int',
	    schema: schema,
	    key: null,
	    isManaged: true
    }
    
    schema.types.add(primInt);
    schema.primitives.add(primInt);
    
    var xField = {
	    _id: 2,
	    name: 'x',
	    type: primInt,
	    optional: false,
	    many: false,
	    key: false,
	    inverse: null,
	    computed: null,
	    traversal: false,
	    isManaged: true
    };
    
    var yField = {
	    _id: 3,
	    name: 'y',
	    type: primInt,
	    optional: false,
	    many: false,
	    key: false,
	    inverse: null,
	    computed: null,
	    isManaged: true,
	    traversal: false
    };
    
    var point = {
	    _id: 4,
	    name: 'Point',
	    schema: schema,
	    key: null,
	    supers: new IdSet(),
	    subclasseses: new IdSet(),
	    defined_fields: new IdSet([xField, yField]),
	    all_fields: new IdSet([xField, yField]),
	    fields: new IdSet([xField, yField]),
	    isManaged: true
    };
    
    xField.owner = point;
    yField.owner = point;
    
    schema.types.add(point);
    schema.classes.add(point);

    return schema;
}
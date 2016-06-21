

"use strict";

class IdSet {
    
    constructor(objs) {
	this.hash = {};
	if (objs) {
	    for (var i = 0; i < objs.length; i++) {
		this.hash[this.keyOf(objs[i])] = objs[i];
	    }
	}
    }
    
    keyOf(obj) {
	// lookup the value of the field that is marked
	// as primary key of this objects schema class.
	if (!this.__key) {
	    // this assumes that IdSets are always used 
	    // homogeneously (i.e. all valid elements have 
	    // the same key field).
	    this.__key = obj.schema_class.key.name; 
	}
	return obj[this.__key];
    }
    
    add(obj) {
	this.hash[this.keyOf(obj)] = obj;
    }
    
    find(pred) {
	for (var k in this.hash) {
	    if (this.hash.hasOwnProperty(k)) {
		if (pred(this.hash[k])) {
		    return this.hash[k];
		}
	    }
	}
    }
    
    has(obj) {
	return this.hash.hasOwnProperty(this.keyOf(obj));
    }
    
    forEach(f) {
	for (var k in this.hash) {
	    if (this.hash.hasOwnProperty(k)) {
		f(this.hash[k]);
	    }
	}
    }
    
    map(f) {
	var s = new ESet([]);
	this.forEach(x => s.add(f(x)));
	return s;
    }
}


function mapInto(obj, semantics) {
    var memo = {};
    
    function build(obj) {
	if (memo.hasOwnProperty(obj._id)) {
	    return memo[obj._id];
	}
	
	var args = {};
	obj.schema_class.all_fields.forEach(fld => {
	    
	    // note that if a field is computed, accessing it
	    // actually computes the result, which is then built;
	    // so we're actually really taking a snapshot of the model here.
	    
	    if (fld.type.isPrimitive()) {
		args[fld.name] = obj[fld.name];
	    }
	    else if (fld.traversal) {
		if (fld.many) {
		    args[fld.name] = obj[fld.name].map(x => build(v));
		}
		else if (!obj[fld.name]) {
		    args[fld.name] = null;
		}
		else {
		    args[fld.name] = build(obj[fld.name]);
		}
	    }
	    else if (fld.inverse != null) {
		// ??? all inverses are cross refs, so lazy...
	    }
	    else { // cross ref, do lazy; TODO: collections
		args[fld.name] = Proxy.create({
		    get: function (proxy, name) {
			// yank out the proxy
			args[fld.name] = build(obj[fld.name]);
			return args[fld.name];
		    }
		});
	    }
	});
	memo[obj._id] = semantics[obj.schema_class.name](obj, args);
	return memo[obj._id];
    }
    
    return build(obj);
}

class MObj {
    constructor(schema_class, id, graph_id, data) {
	this.schema_class = schema_class;
	this._id = id;
	this._graph_id = graph_id;
	this._data = data;
	this.isManaged = true;
    }
    
    toString() {
	return '<' + this.schema_class.name + ': #' + this._id + '>';
    }
}




class EvalSchema  {
    Schema(self) {
	var factory = {_ids: 0};
	self.classes.forEach(klass => {
	    factory[klass.name] = klass.make;
	});
	return factory;
    }
    
    Primitive(self) {
	return {
	    isPrimitive: true,
	    key: null,
	    checkType: function(val) {
		switch (self.name) {
		case 'str': return (typeof val === 'string');
		case 'int': return (typeof val === 'number');
		case 'bool': return (typeof val === 'boolean');
		case 'real': return (typeof val === 'number');
		default: throw 'unknown primitive: ' + self.name;
		}
	    },
	    defaultValue: function() {
		switch (self.name) {
		case 'str': return '';
		case 'int': return 0;
		case 'bool': return false;
		case 'real': return 0.0;
		default: throw 'unknown primitive: ' + self.name;
		}
	    }
	}
    }
    
    Class(self) {
	return {
	    isPrimitive: false,
	    name: self.name,
	    key: self.key,
	    defaultValue: null,
	    checkType: function (val) {
		if (!val) {
		    return true;
		}
		if (!val.isManaged) {
		    return false;
		}
		
		function subclass(cls1, cls2) {
		    if (cls1.name === cls2.name) {
			return true;
		    }
		    for (var sup of cls1.supers) {
			if (subclass(sup, cls2)) {
			    return true;
			}
		    }
		    return false;
		}

		return subclass(val.schema_class, self);
	    },
	    make: function () {
		var data = {};
		
		self.all_fields.forEach(fld => fld.init(data));
		
		function handle(fieldName, func, val) {
		    var fld = self.allFields.find(x => x.name === fieldName);
		    if (!fld) {
			throw "No such field " + fieldName + " in class " + name;
		    }
		    return fld[func](data, val);
		}
		
		var result = new MObj(self, self.schema._ids++, self.schema, data);
		
		result.prototype = Object.create(Proxy.create({
		    get: function (proxy, name) {
			return handle(name, 'get', undefined);
		    },
		    set: function (proxy, name, val) {
			return handle(name, 'set', val);
		    },
		    iterate: function (proxy, name) {
			return handle(name, 'iterate', undefined);
		    }
		}));
		
		return result;
	    }
	};
    }

    Field(self) {
	return {
	    name: self.name,
	    init: function (data) {
		if (self.computed) {
		    // computed is already built into a function
		    data[self.name] = self.computed;
		}
		else if (self.many) {
		    if (self.type.key !== null) {
			data[self.name] = new IdSet([]);
		    }
		    else {
			data[self.name] = [];
		    }
		}
		else {
		    data[self.name] = self.type.defaultValue();
		}
	    },
	    get: function (data) {
		if (self.computed) {
		    return data[self.name](data); // call it with data as "env"
		}
		return data[self.name];
	    },
	    set: function (data, val) {
		if (!self.type.checkType(val)) {
		    throw "invalid type for field " + self.name;
		}
		if (!val && !self.optional) {
		    throw "optional field cannot be null";
		}
		data[self.name] = val;
	    }
	}
	
    }
    
}

// left-biased: a's methods will override b's if any.
function merge(a, b) {
    return Proxy.create({
	get: function (proxy, name) {
	    var obj = {};
	    for (var k in a[name]) {
		if (a[name].hasOwnProperty(k)) {
		    obj[k] = a[name][k];
		}
	    }
	    Object.setPrototypeOf(obj, b[name]);
	    return obj;
	}
    });
}

class Add {
    constructor (lhs, rhs) {
	this.lhs = lhs;
	this.rhs = rhs;
    }
}

class Lit {
    constructor (val) {
	this.val = val;
    }
}


function buildIt(obj, behavior) {
    console.log("Building " + JSON.stringify(obj));
    
    if (typeof obj !== 'object') {
	console.log("Not an object; returning as is: " + obj);
	return obj;
    }
	
    for (var k in obj) {
	if (obj.hasOwnProperty(k)) {
	    console.log("Recursing on " + k);
	    obj[k] = buildIt(obj[k], behavior);
	}
    }

    console.log("Building really " + obj.constructor.name + ' (' + JSON.stringify(obj) + ')');
    Object.setPrototypeOf(obj, behavior[obj.constructor.name]);
    return obj;
}

var ExpCheck = {
	Add: {
	    check: function () {
		return this.lhs.check() && this.rhs.check();
	    }
	},
	Lit: {
	    check: function() {
		console.log('Checking Lit: ' + this.print());
		return typeof this.val === 'number';
	    },
	    
	    print: function () {
		return "bla" + Object.getPrototypeOf(Object.getPrototypeOf(this)).print.apply(this, []);
	    }
	}
};

var ExpPrint = {
	Add: {
	    print: function () {
		return this.lhs.print() + ' + ' + this.rhs.print();
	    }
	},
	Lit: {
	    print: function() {
		return this.val.toString();
	    }
	}
};

var ExpEval = {
	Add: {
	    eval: function () {
		return this.lhs.eval() + this.rhs.eval();
	    }
	},
	Lit: {
	    eval: function () {
		return this.val;
	    }
	}
};

var exp = new Add(new Lit(1), new Lit(2));
var exp2 = buildIt(exp, merge(ExpCheck, merge(ExpPrint, ExpEval)));

console.log(exp2.eval());
console.log(exp2.check());
console.log(exp2.print());

var exp2 = buildIt(exp, merge(ExpCheck, ExpPrint));

console.log(exp2.check());
console.log(exp2.print());


/*
 * Concerns
 * - immutable/locking
 * - maximal sharing
 * - logging
 * - contracts/invariants (+syntax)
 * - inverses (+syntax)
 * - cross references (+syntax)
 * - authorization (+ model)
 * - computed properties (+ syntax)
 * - type checks (+ syntax)
 * - multiplicity/cardinality (+ syntax)
 * - observing/reactivenes
 */


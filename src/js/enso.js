
define (function() {

  fs = require("fs");
    
  S = function() {
   return  Array.prototype.slice.call(arguments).join("");
  }
    
  puts = function(obj) {
    console.log("" + obj);
  }
  
  EnsoHash = function(init) {
    var data = new Object();
    this.has_key_P = function(key) { return data.hasOwnProperty(key); };
    this._get = function(key) { return data[key]; };
    this.keys = function() { 
      var keys = [];
      for (k in data) {
        if (data.hasOwnProperty(k))
          keys.push(k);
      }
      return keys;
    }
  }
  
  
  System = {
    readJSON: function(path) {
      return JSON.parse(fs.readFileSync(path));
    },
    test_type: function(obj, type) {
      return obj != null && obj.is_a_P(type); // TODO: why does this work, but "obj instanceof type" does not?
    }
  }
  
  Object.prototype.raise = function(msg) { throw msg }
  
  compute_rest_arguments = function(args, num) { 
    var x = new Array;
    puts("REST");
    while (num < args.length)
      x.push(args[num++]);
    puts("REST  " + x);
    return x;
  }

  Function.prototype.call_rest_args$ = function(obj, fun, args, rest) {
    var len = arguments.length;
    var newargs = [];
    var i;
    for (i = 1; i < len-2; i++) 
      newargs.push(arguments[i]);
    newargs = newargs.concat(arguments[len-1]); 
    puts("CALL_REST " + a + ", " + newargs);
    return this.apply(a, newargs);
  }
  
  Object.prototype.has_key_P = Object.prototype.hasOwnProperty
  Array.prototype.each = function(fun) {  // Array.prototype.forEach;
    var i;
    for (i = 0; i < this.length; i++) {
      fun(this[i], i);
    }
  };
  
  Array.prototype.each_with_index = Array.prototype.each;
  
  Array.prototype.map = function(fun) {  // Array.prototype.forEach;
    var i;
    //puts("MAP " + this);
    var result = new Array;
    for (i = 0; i < this.length; i++) {
      result.push(fun(this[i]));
    }
    return result;
  };
  
  Array.prototype.select =  function(fun) {  // Array.prototype.filter;
    var i;
    //puts("SELECT " + this);
    var result = new Array;
    for (i = 0; i < this.length; i++) {
      //puts("  SELECT " + this[i]);
      if (fun(this[i]))
        result.push(this[i]);
    }
    return result;
  };
  Array.prototype.flat_map = function(fun) { 
    var x = new Array; 
    this.each(function(obj) { 
      x = x.concat(fun(obj));
    }); 
    return x; 
  };
  Array.prototype.concat = function(other) {
    var x = new Array; 
    this.each(function(obj) { 
      x.push(obj);
    }); 
    other.each(function(obj) { 
      x.push(obj);
    }); 
    return x; 
  };
  Array.prototype.union = function(other) {
    var x = new Array; 
    this.each(function(obj) { 
      x.push(obj);
    }); 
    other.each(function(obj) {
      if (!x.contains(obj))
        x.push(obj);
    }); 
    puts("UNION " + this + " +++ " + other + " = " + x);
    return x; 
  };
  
    
  
  
  Object.prototype.each = function (cmd) {
    for (var i in this) {
      if (this.hasOwnProperty(i)) {
        var a = this[i];
        cmd.call(a, i, a)
      }
    }
  }

  _fixup_method_name = function(name) { 
    if (name.slice(-1) == "?") { 
      name = name.slice(0,-1) + "_P";
    } 
    return name; 
  }
  Object.prototype.find = function(pred) { 
    var result = null;
    this.each( function(a) {
      if (pred(a)) {
        result = a; 
      }
    });
    return result;
  }
  Object.prototype.is_a_P = function(type) { return this instanceof type; }
  Object.prototype.define_singleton_value = function(name, val) { this[_fixup_method_name(name)] = function() { return val;} }
  Object.prototype.define_singleton_method = function(proc, name) { this[_fixup_method_name(name)] = proc }
  String.prototype.to_s = function() { return this }
  Object.prototype.to_s = function() { return "" + this }
  Object.prototype._get = function(k) { return this[k] }
  String.prototype._get = function(k) { if (k >= 0) { return this[k] } else { return this[this.length+k] } }
  Object.prototype._set = function(k, v) { this[k] = v; return v; }
  String.prototype.gsub = String.prototype.replace;
  String.prototype.index = String.prototype.indexOf;
  string$split = String.prototype.split;
  String.prototype.split = function(sep, lim) {
    return string$split.call(this, sep, lim).filter(function(x) { return x != ""; });
  }
  string$slice = String.prototype.slice;
  String.prototype.slice = function(start, len) {
    if (len != undefined)
      len = start + len;
    return string$slice.call(this, start, len);
  }
  
  EnsoBaseClass = {
    new: function() {}
  }
  // put enso global methods here
  EnsoBaseClass.new.prototype = {
    toString: function() { return this.to_s(); },
    _get: function(k) { 
      return this[k](); 
    },
    send: function(k) {
      puts("SEND " + k + ": " + this[k]);
      return this[k]();
    }
  }

  MakeClass = function(base_class, instance_spec) {
      // NewClass = MakeClass(ParentClass, { 
      //    _class_: { 
      //         class_var1: init-value,            // @@var
      //         class_method: function(...) {...}  // def self.class_method(...) ...
      //         // the "new" method gets added here
      //     },
      //     initialize: function(..) {             // def intialize(..) 
      //        this.$.instance_var = init-value;   //    @instance_vaf = ...
      //     },
      //     instance_method: function(a, b) {    // def instance_method(a, b, *args)
      //        var self = this;                  // default preamble
      //        args = get_rest_arguments(arguments, 2)  // autogenerated call to set up rest args
      //        self.$.var                          // @var
      //        self._class_.var                    // @@var
      //        self.super$.foo.apply(self, arguments);    // super
      //        self.super$.foo.call(self, arg1, arg2...); // super(arg1, arg2)  # in foo method
      //        o.foo(a,b,*c)                       // o.foo.call_method(a, b, c)  # where call_method is in the library
      //     }
      //  }
      // return value: the value of _class_ is the return value (or a synthetic new _class_ is added for you)
          
      // base_class is the *class* object of the base class
      // instance_spec is the record containing fields for this object
      //    which can contain a "_class_" field to specify its class data
      if (!instance_spec) {
        instance_spec = base_class;
        base_class = EnsoBaseClass;
      }
      // create a class structure if there isn't one (for example, when inheriting Array)
      if (typeof base_class === "function") {
        var temp = new Object(EnsoBaseClass);
        temp.new = base_class;
        base_class = temp;
      }

      // get the prototype of the base constructor function      
      var parent_instance_proto = base_class.new.prototype;
      // connect this instance_spec bindings to inherit the parent's instance_spec 
      instance_spec.__proto__ = parent_instance_proto;
      instance_spec.super$ = {};
      /*
      // if there are mixins, then a clone of the mixin's prototype is inserted between object and base
      if (instance_spec.hasOwnProperty("include")) {
    		if (! instance_spec.hasOwnProperty("_eigen_")) {
    			instance_spec._eigen_ = Object.create({});
      	    	instance_spec._eigen_.__proto__ = instance_spec.__proto__
      	    	instance_spec.__proto__ = instance_spec._eigen_
    		}
    		for (var i=0,len=instance_spec.include.length; i<len; i++) {
    			var methods = instance_spec.include[i]._instance_spec_._methods_()
    			for (var m in methods) {
    				if (methods.hasOwnProperty(m))
    					instance_spec._eigen_[m] = methods[m] 
    			}
  	    }
      }*/
      // make sure there is a class object 
      instance_spec._class_ = instance_spec.hasOwnProperty("_class_") ? instance_spec._class_ : Object.create({});
      // connect this object's class data to the base class data 
      instance_spec._class_.__proto__ = base_class;
      // make sure there is an initializer function
      instance_spec.initialize = instance_spec.initialize || function() {
          if (parent_instance_proto.hasOwnProperty("initialize")) {
              parent_instance_proto.initialize.apply(this, arguments);
          }
      };

      // create the constructor function      
      var constructor = function() {
         var obj = Object.create(instance_spec);
         obj.$ = {};
         instance_spec.initialize.apply(obj, arguments);
         return obj;
      }
      // set its prototype, even thought it is not actually used view "new"
      // it is accessed above
      constructor.prototype = instance_spec;
      // fill in the "new" function of the class
      instance_spec._class_.new = constructor;
      instance_spec._class_.super$ = base_class;
      // return the new class
      return instance_spec._class_;
  }  

  EnsoProxyObject = EnsoBaseClass;
  
  MakeModule = MakeClass;

  MakeMixin = function(instance_spec) {

      // make sure there is a class object 
      instance_spec._class_ = instance_spec.hasOwnProperty("_class_") ? instance_spec._class_ : Object.create({});

      // get all methods defined in this mixin and its parents
      instance_spec._methods_ = function() {
      	var methods = [];
      	if (instance_spec.hasOwnProperty("include")) {
    			for (var i=0,len=instance_spec.include.length; i<len; i++) {
    				var incld = instance_spec.include[i]
    				methods = methods.concat(incld._instance_spec_._methods_())
    			}
      	}
      	for (var attr in instance_spec) {
      		if (attr!="include" && attr.indexOf("_")!=0 && instance_spec.hasOwnProperty(attr)) { 
      		  methods[attr] = instance_spec[attr]
      		 }
      	}
      	return methods
      }
     
      // return the new class
      return instance_spec._class_;
   }
   
   Enumerable = MakeMixin({
     all_P: function(pred) { var x = true; this.each(function(obj) { x = x && pred(obj) }); return x; },
     any_P: function(pred) { var x = false; this.each(function(obj) { x = x || pred(obj) }); return x; },
   });

})
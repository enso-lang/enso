'use strict'

function mix(base, ...mixins) {
    return mixins.reduce((c, mixin) => mixin(c), base);
}

  var Integer = Number;
  var Float = Number;
  var Numeric = Number;
  var Fixnum = Number;

var config = {
  writable: true,
  configurable: true
};
function extendObjectPrototype(name, value) {
  config.value = value;
  Object.defineProperty(Object.prototype, name, config);
}

extendObjectPrototype('to_s', function() { return "<OBJECT>" })
extendObjectPrototype('raise', function(msg) { puts(msg); throw "ERROR: " + msg; })
extendObjectPrototype('instance_eval', function(fun) { fun.apply(this); })
extendObjectPrototype('has_key_P', Object.prototype.hasOwnProperty)

class TrueClass {}
class FalseClass {}
extendObjectPrototype('is_a_P', function(type) { 
  var t = typeof this;
  if (t == "string" && type == String)
    return true;
  if (t == "number" && (type == Number || type == Float))
    return true;
  if (this == true && type == TrueClass)
    return true;
  if (this == false && type == FalseClass)
    return true;
  if (typeof type == "function")
    return this instanceof type;
  return false;
});
extendObjectPrototype('define_singleton_value', 
	function(name, val) { this[_fixup_method_name(name)] = function() { return val;} });
extendObjectPrototype('define_singleton_method', 
	function(proc, name) { this[_fixup_method_name(name)] = proc } );

extendObjectPrototype('get$', function(k) { return this[k] })
extendObjectPrototype('set$', function(k, v) { this[k] = v; return v; })


extendObjectPrototype('include_P', 
  function(obj) {  // Array.prototype.filter;
    var i;
    for (i = 0; i < this.length; i++) {
      if (this[i] == obj)
        return true;
    }
    return false;
  });  

extendObjectPrototype('clone', 
  function() {  // Array.prototype.forEach;
    var result = new Object;
    for (var i in this) {
      if (this.hasOwnProperty(i))
        result[i] = this[i];
    }
    return result;
  });

extendObjectPrototype('each', 
  function (cmd) {
    for (var i in this) {
      if (this.hasOwnProperty(i)) {
        var a = this[i];
        cmd.call(a, i, a)
      }
    }
  });

extendObjectPrototype('find', 
  function(pred) { 
    var result = null;
    this.each( function(a) {
      if (result == null && pred(a)) {
        result = a; 
      }
    });
    return result;
  });

extendObjectPrototype('find_first', 
  function(pred) {
    var result = null;
    this.each( function(a) {
      if (result == null) {
        var item = pred(a);
        if (item) 
          result = item; 
      }
    });
    return result;
  });

  function puts(...obj) {
    console.log(...obj);
  }

  // running in node
  var fs = require("fs");
  var ARGV = process.argv.slice(2);
  
  function S() {
   return  Array.prototype.slice.call(arguments).join("");
  }
      
  class EMap extends Map {
    static new(...args) { return new EMap(...args) };
    
    constructor(init = {}) {
      super();
      var k;
      for (k in init) {
        if (init.hasOwnProperty(k))
          this.set(k, init[k]);
      }
    }
    
    clone() {
      var n = EMap.new();
      this.forEach((v,k)=>n.set(k,v))
      return n
    }
    has_key_P(key) { return this.has(key); };
    
    inspect() {
      return "<HASH " + this.size_M() + ">";
    }
    delete_M(key) {
        this.delete(key);
    };
    size_M() { 
      return this.size;
    };
    each(fun) {
      this.forEach((v,k)=> fun(k,v));
    };
    each_pair(fun) {
   	  for (const k of this.entries()) {
          fun(k[0], k[1]);
      }
    }
    each_value(fun) {
   	  for (const k of this.values()) {
          fun(k);
      }
    };
    empty_P() { 
			return this.size == 0
	  }
  }
  EMap.prototype.get$ = Map.prototype.get;
  EMap.prototype.set$ = Map.prototype.set;
  
  class CompatStream {
    constructor(s) {
      this.s = s;
    }
    push(d) {
      if (this.s == true)
        document.write(("" + d).replace(/</g, "&lt").replace(/>/, "&gt").replace(/ /g, "&nbsp;").replace(/\n/, "<br>"));
      else if (this.s)
        this.s.write(d);
      else
        console.log(d);
    }
  };
  
  const path = require('path');

  var File = {
    absolute_path: function(sub, base = null) {
      if (base == null)
	      return path.resolve(sub)
      else
	      return path.resolve(sub, base)
    },
    exists_P: function(p) { 
      return fs.existsSync(p);
    },
    load_file_map: function () {
      return System.readJSON("model_index.json");
    },
    read_header: function (path) {
      var data = fs.readFileSync(path).toString();
      var pos = data.indexOf("\n");
      if (pos == -1)
        return data;
      else
        return data.substring(0, pos);
    },
    write: function(callback, path) {
      stream = fs.createWriteStream(path, {
			  flags: 'w',
			  defaultEncoding: 'utf8',
			  mode: 0o666,
			  autoClose: true
			});
      callback(stream);
      stream.close();
      console.log('Written to ' + path);
			}
  };
  
  var System = {
    popupMenu(items) {
			const {remote} = window.require('electron');
			const {Menu, MenuItem} = remote;
			
			const menu = new Menu();
			for ( key_name in items) 
        if (items.hasOwnProperty(key_name)) {
          var val = items[key_name]
				  if (val == null)
	    			menu.append(new MenuItem({type: 'separator'}));
	    	  else
	  			  menu.append(new MenuItem({label: key_name, click: val }));
			   }
			// menu.append(new MenuItem({label: 'MenuItem2', type: 'checkbox', checked: true}));
			
			  menu.popup(remote.getCurrentWindow());
		},

    is_javascript: function() { return true },
    JSHASH: function() { return {} },
    max: function(a, b) {
      return a > b ? a : b;
    },
    min: function(a, b) {
      return a > b ? b : a;
    },
    readJSON: function(path) {
      return JSON.parse(fs.readFileSync(path));
    },
    writeJSON: function(path, data) {
      fs.writeFileSync(path, JSON.stringify(data, null, 2));
    },
    test_type: function(obj, type) {
      if (obj == null)  // this also has undefined == true
        return false;
      return obj.is_a_P(type); // TODO: why does this work, but "obj instanceof type" does not?
    },
    assign: function(target, arg1) { return Object.assign(target, arg1) },
    stdout: function() { return new CompatStream(typeof process == 'undefined' ? true : process.stdout); },
    stderr: function() { return new CompatStream(typeof process == 'undefined' ? null : process.stderr); },
  }
    
  Array.prototype.values = function() { return this; }
  Array.prototype.empty_P = function() { return this.length == 0; }
  Array.prototype.any_P = Array.prototype.some;
  Array.prototype.all_P = Array.prototype.every;
  Array.prototype.each = function(fun) {  // Array.prototype.forEach;
    var i;
    for (i = 0; i < this.length; i++) {
      fun(this[i], i);
    }
  };
  Array.prototype.each_with_index = Array.prototype.each;
  Array.prototype.clone = function() {  // Array.prototype.forEach;
    var i;
    var result = new Array;
    for (i = 0; i < this.length; i++) {
      result.push(this[i]);
    }
    return result;
  };
  Array.prototype.index = Array.prototype.indexOf;
  
  String.prototype.inspect = function() {
     return "\"" + this.replace(/([\\"'])/g, "\\$1").replace(/\0/g, "\\0") + "\"";
  } 
  String.prototype.repeat = function(n) {
    var result = "";
    for (var i = 0; i < n; i++)
      result = result + this;
    return result;
  }
  String.prototype.size_M = function() { return this.size; }
  
  Array.prototype.size_M = function() { return this.length }
  Array.prototype.map = function(fun) {  // Array.prototype.forEach;
    var result = new Array;
    this.each(function (x) { 
      result.push(fun(x));
    })
    return result;
  };
 
  Array.prototype.select =  function(fun) {  // Array.prototype.filter;
    var i;
    var result = new Array;
    for (i = 0; i < this.length; i++) {
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
      // if (!x.contains(obj))
        x.push(obj);
    }); 
    return x; 
  };
  
  function _fixup_method_name(name) { 
    if (name.endsWith("?")) { 
      name = name.slice(0,-1) + "_P";
    } 
    return name; 
  }
  
  String.prototype.size_M = function() { return this.length }
  String.prototype.to_s = function() { return this }
  String.prototype.to_i = function() { return Number(this) }
  String.prototype.rjust = function(len, char) { return (char.repeat(len)+this).slice(-len) }
  Number.prototype.to_i = function() { return this }
  Number.prototype.to_s = function() { return this.toString(); }
  Number.prototype.to_hex = function() { return this.toString(16).toUpperCase() }
  Number.prototype.abs = function() { return Math.abs(this) }
  Number.prototype.downto = function(cb, t) {
	  var i = this;	
	  while (i >= t) { cb(i--); }
	  return this;
	};
  Number.prototype.upto = function(cb, t) {
	  var i = this;	
	  while (i <= t) { cb(i++); }
	  return this;
	};
  Array.prototype.to_s = function() { return "<ARRAY " + this.length + ">" }
  Array.prototype.first = function() { return this[0]; }
  String.prototype._get = function(k) { 
    if (k >= 0) { 
      return this[k] 
    } else { 
      return this[this.length+k] 
    } 
   }
  Array.prototype._get = function(k) {
    if (System.test_type(k, Range)) {
      return this.slice(k.$.a, this.length+1-(k.$.b*-1))
    } else if (k >= 0) { 
      return this[k] 
    } else { 
      return this[this.length+k] 
    }
  }
  String.prototype.set$ = function(k, v) { raise("Strings are immutable"); }
  //String.prototype.gsub = String.prototype.replace; //NOTE: gsub!=replace, gsub replaces ALL instances
                                                      //  also, beware the use case of "aaa".gsub("a"," a ")
  String.prototype.gsub = function(from, to) { return this.split(from).join(to) }
  String.prototype.index = String.prototype.indexOf;
  String.prototype.to_sym = function() { return this; }
  String.prototype.start_with_P = String.prototype.startsWith;
  String.prototype.end_with_P = String.prototype.endsWith;
  String.prototype.rindex_M = String.prototype.lastIndexOf;
  
  String.prototype.split_M = function(sep, lim) {
    return this.split(sep, lim).filter(function(x) { return x != ""; });
  }
  String.prototype.slice_M = function(start, len) {
    if (len != undefined)
      len = start + len;
    return this.slice(start, len);
  }
  
  class EnsoBaseClass {
    send(method, ...args) {
      var fun = this[method.replace("?", "_P")];
      if (!fun) raise("Undefined method " + method + " for " + this);
      var val = fun.apply(this, args);
      return val;
    }
    define_getter(name, prop) {
      this[name] = function() { return prop.get() }    // have to get "self" right
    }
    define_setter(name, prop) {
      this["set_" + name] = function(val) { 
        prop.set(val)
      }  // have to get "self" right
    }
    get$(k) { return this[k].call(this); }
    set$(k, v) { 
      return this["set_" + k].call(this, v);
    }
    method(m) { 
      var self = this; 
      return function() { 
        return self[m].apply(self, arguments); 
    }}
    
    p(arg) {
	    return arg.inspect().toString();
    }
    to_s() {             
       var kind = this.__classname__;
       if (this.schema_class)
         kind = this.schema_class().name();
       var info = "";
       if (typeof this.name == "function")
         info = this.name();
       else if (this._id)
         info = this._id;
       return "<[" + kind + " " + info + "]>";
    }
    respond_to_P(method) { 
      return this[method.replace("?", "_P")]; 
    }
  }

  class EnsoProxyObject extends EnsoBaseClass { 
    constructor() {
      super();
    }
  }
  
  var Enumerable = function(parent) {
     return class extends parent {
       all_P(pred) { 
         var x = true; 
         this.each(function(obj) { x = x && pred(obj) }); 
         return x; 
       }
       any_P(pred) { 
         var x = false; 
         this.each(function(obj) { x = x || pred(obj) }); 
         return x; 
       }
       map(fun) {
         var r = [];
         this.each(function(obj) { r.push( fun(obj) ) });
         return r;
       }
       each_with_index(cmd) {
         var i = 0;
         this.each(function(obj) { 
           cmd(obj, i);
           i++;
         })
       }
     }};
   Enumerable.map = Array.prototype.map;

   class Range extends Enumerable(EnsoBaseClass) {
      constructor(a, b) {
        this.a = a;
        this.b = b;
      }
      each(proc) {
        var i;
        for (i = this.a; i <= this.b; i++)
          proc(i);
      }       
    };

module.exports = {
	mix: mix,
	S: S,
	System: System,
	EMap: EMap,
	File: File,
	Integer: Integer,
	Numeric: Numeric,
	TrueClass: TrueClass,
	FalseClass: FalseClass,
	Range: Range,
	EnsoBaseClass: EnsoBaseClass,
	EnsoProxyObject: EnsoProxyObject,
	Enumerable: Enumerable,
	puts: puts
}
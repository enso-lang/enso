#import('dart:io');
#import("dart:json");

void debug(str) {
  // print(str);
}

class ManagedInstance {
  List fixups;
  ManagedInstance() {
    fixups = new List(); 
  }
  static load(json) { 
    var  j = JSON.parse(json);
    var resolver = new ManagedInstance();
    var root = new LoadedManagedObject(j, resolver);
    resolver.resolve(root);
    return root;
  }
  void makeObj(spec, binder) {
    if (spec is String) {
      // debug("SPEC ${spec}");
      fixups.add((root) { binder(lookup(root, spec)); });
    } else {
      binder(new LoadedManagedObject(spec, this));
    }
  }
  resolve(root) {
    fixups.forEach((fix) { fix(root); });
  }
  lookup(current, path) {
    if (path == "" || path == "/")
      return current;
    debug("PATH ${current.toString()} : $path");
    var r;
    // indexed: [name]
    r = const RegExp("^\\[([^\\]]+)\\](.*)").firstMatch(path);
    if (r !== null) {
      debug("Keyed ${r[1]}");
      return lookup(current[r[1]], r[2]);
    }
    // field: /field
    r = const RegExp("^\\/([^\\/[]+)(.*)").firstMatch(path);
    if (r !== null) {
      debug("FIELD ${r[1]}");
      return lookup(current[r[1]], r[2]);
    }
    throw ("bad path ${path}");
  }
}

class LoadedManagedObject {
  var data;
  String class_name;
  LoadedManagedObject(json, resolver) {
    debug("MAKE ${json['class']}");
    this.data = new Map();
    json.forEach((String key, value) {
      if (key == "class")
        this.class_name = value;
      else if (key.endsWith("=")) { // primitive
        var name = key.substring(0,key.length-1);
        debug("SET $name=$value");
        data[name] = value;
      } else {
        var name = key;
        if (value is List) {
          if (key.endsWith("#")) {
            name = key.substring(0, key.length-1);
            data[name] = new LoadedKeyedCollection();
          } else
            data[name] = new List();
          value.forEach((sub) {
            resolver.makeObj(sub, (obj) {
              debug( " ADD $name: ${obj}");
              data[name].add(obj);
            });
          });
        } else {
          resolver.makeObj(value, (obj) {
              debug( " SET $name = ${obj}");
              data[name] = obj;
            });
        }
      }
    });
  }

  operator [](name) {
    if (!data.containsKey(name))
      throw "unknown field $name for $class_name";
    return data[name];
  }
  operator []=(name, value) {
    if (!data.containsKey(name))
      throw "unknown field $name for $class_name";
    return data[name] = value;
  }
  noSuchMethod(String method, List args) {
    debug("?? $method");
    if (method.startsWith("get:"))
      return this[method.substring(4)];
    else
      throw "Calling method $method on managed object";
  }
}

class LoadedKeyedCollection {
  Map map;
  List vals;
  LoadedKeyedCollection() {
    map = new Map();
    vals = new List();
  }
  add(item) {
    map[item.name] = item;
    vals.add(item);
  }
  operator [](key) {
    if (key is int)
      return vals[key];
    else
      return map[key];
  }
}

void main() {
  File f = new File('schema_schema.json');
  Future<String> finishedReading = f.readAsText(Encoding.ASCII);
  finishedReading.then((text) {
    var obj = ManagedInstance.load(text);
    print( obj.types[0].name );
    print( obj.types[0].defined_fields[0].name );
    print( obj.types[0].defined_fields[0].type.name );
    return obj;
  });
}

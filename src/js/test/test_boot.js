'use strict'


var handler = {
    get: function(target, name) {
        console.log("GET", target, name);
        return target[name](99);
    }
};
var proxy = new Proxy({p:x=>x, q: y=>2*y}, handler);

module.exports = {p: proxy}

/*
var fs = require('fs')

var data = fs.readFileSync("enso.js")
console.log("file with ", data)
console.log("CWD=", process.cwd())

var Enso = require('enso')
console.log(Enso)

console.log("Hi there!")


console.log({ f1: 3, new: 'foo' })

function mix(base, ...mixins) {
    return mixins.reduce((c, mixin) => mixin(c), base);
}

function N(superclass) {
    return class extends superclass {
     fooN() { console.log("NNNN") }
   }
}

function M(superclass) {
    return class extends mix(superclass, N) {
     fooM() { console.log("MMMMM") }
   }
}

class X extends mix(Enso.EnsoBaseClass, M) {
    static new(...args) { return new X(...args) };
   
    constructor() {
      super();
      this.foo = 3;
      this.name = "will";
      this.new = 99;
    }
    base() {
      this.fooM();
      this.fooN();
			return "DONE";
    }
}

console.log(X.new().base())

*/
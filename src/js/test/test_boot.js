

require("../enso.js")

C = MakeClass("C", null, [], 
    function() {
    },
    function(super$) {
      this.a = function(param) {
				return param*2;
			}
		}
	)
	
D = MakeClass("D", C, [],
    function() {
    },
    function(super$) {
      this.b = function(param) {
				return 4 * super$.a(param);
			}
		}
	)

var a = C.new();
var d = D.new();

console.log("a.a() = ", a.a(3));
console.log("d.a() = ", d.a(3));
console.log("d.b() = ", d.b(3));

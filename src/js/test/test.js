
var cwd = process.cwd() + '/';
console.log("CWD", cwd)
var Load = require(cwd + "core/system/load/load.js");

model = Load.load("schema.schema")
model = Load.load("code_js.grammar")
model = Load.load("diagram.schema")
model = Load.load("stencil.schema")
model = Load.load("schema.stencil")


var Stencil = require(cwd + "core/diagram/code/stencil.js");
var data_file =  "schema.schema" // "door.state_machine" //  "state_machine.schema"; //  
var stencil = new Stencil.StencilFrame(null, null, null)
stencil.set_path(data_file)			  

console.log("DONE")
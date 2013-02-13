var requirejs = require('requirejs');

requirejs.config({
    //Pass the top-level main.js/index.js require
    //function to requirejs so that node modules
    //are loaded relative to the top-level JS file.
    nodeRequire: require,
   baseUrl: 'js',
});


requirejs(["enso", "./core/system/boot/meta_schema"],
function(Enso, Boot) {

 x = Boot.load_path("/Users/wcook/enso/src/core/system/boot/schema_schema.json");
console.log("x._id = " + x._id()) ;
console.log("Test = " + x.types().to_s());
console.log("Test = " + x.types()._get("Primitive").name()) ;
console.log("Test = " + x.types()._get("Primitive").to_s()) ;
 
})
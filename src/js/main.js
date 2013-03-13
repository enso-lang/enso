requirejs(["enso", "./core/system/boot/meta_schema"],

function(Enso, Boot) {
  x = Boot.load_path("/core/system/boot/schema_schema.json");
  console.log("x._id = " + x._id()) ;
  console.log("Test1 = " + x.toString());
  console.log("Test2 = " + x.types().to_s());
  console.log("Test3 = " + x.types()._get("Primitive").name()) ;
  console.log("Test4 = " + x.types()._get("Schema").schema()) ;
  console.log("Test5 = " + x.types()._get("Primitive").to_s()) ;
  console.log("Test6 = " + x.types()._get("Class").all_fields()) ;
  console.log("Test7 = " + x.types()._get("Class").defined_fields()) ;
  console.log("Test8 = " + x.types()._get("Class").supers()) ;
});

requirejs([
  "enso",
  "core/system/load/load",
  "core/grammar/render/layout"
],
function(Enso, Load, Layout) {
  m = Load.load('grammar.grammar');
  g = Load.load(S("grammar", ".grammar"));
  System.stderr().push(S("## Printing ", ARGV._get(0), "...\n"));
  Layout.DisplayFormat.print(g, m, out, false); 
})

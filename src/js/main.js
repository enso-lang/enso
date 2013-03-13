requirejs(["enso", "./core/system/boot/meta_schema"],

function(Enso, Boot) {
  x = Boot.load_path("./core/system/boot/schema_schema.json");
  puts("x._id = " + x._id()) ;
  puts("Test1 = " + x.toString());
  puts("Test2 = " + x.types().to_s());
  puts("Test3 = " + x.types()._get("Primitive").name()) ;
  puts("Test4 = " + x.types()._get("Schema").schema()) ;
  puts("Test5 = " + x.types()._get("Primitive").to_s()) ;
  puts("Test6 = " + x.types()._get("Class").all_fields()) ;
  puts("Test7 = " + x.types()._get("Class").defined_fields()) ;
  puts("Test8 = " + x.types()._get("Class").supers()) ;
});

requirejs([
  "enso",
  "core/system/load/load",
  "core/grammar/render/layout"
],
function(Enso, Load, Layout) {
  m = Load.load('grammar.grammar');
  g = Load.load(S("grammar", ".grammar"));
  System.stderr().push(S("## Printing ", "grammar.grammar", "...\n"));
  Layout.DisplayFormat.print(g, m, System.stdout, false); 
})

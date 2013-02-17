define([
  "core/system/library/schema",
  "core/system/boot/meta_schema",
  "core/grammar/parse/parse",
  "core/schema/tools/union",
  "core/schema/tools/rename",
  "core/system/load/cache"
],
function(Schema, MetaSchema, Parse, Union, Rename, Cache) {

  var Load ;

  Load = {
    load: function(name) {
      return Loader.load(name);
    } ,

    Load_text: function(type, factory, source, show) {
      if (show === undefined) show = false;
      return Load.load_text(type, factory, source, show);
    } ,

    Loader: Loader.new() ,

  };
  return Load;
})

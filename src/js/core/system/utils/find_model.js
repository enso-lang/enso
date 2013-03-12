define([
],
function() {
  var FindModel ;
  var FindModel = MakeClass("FindModel", null, [],
    function() {
      this.file_map = function() {
        var self = this; 
        if (self.$.file_map == null) {
          self.$.file_map = File.create_file_map("..");
        }
        return self.$.file_map;
      };

      this.find_model = function(block, name) {
        var self = this; 
        var path;
        if (File.exists_P(name)) {
          return block(name);
        } else {
         puts("CHECK " + name);
          path = self.file_map()._get(name);
          if (! path) {
            self.raise(EOFError, S("File not found ", name));
          }
          return block(path);
        }
      };
    },
    function(super$) {
    });

  FindModel = {
    FindModel: FindModel,

  };
  return FindModel;
})

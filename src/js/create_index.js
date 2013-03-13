fs = require("fs");

function walk(dir, block) {
  var list = fs.readdirSync(dir);
  for (var i = 0; i < list.length; i++) {
    var name = list[i];
    var path = dir + '/' + name;
    var stat = fs.statSync(path);
    if (stat && stat.isDirectory()) {
      walk(path, block);
    } else {
      block(name, path);
    }
  }
};

map = {}
count = 0;
walk(".", function(name, path) {
  ext = name.slice(name.length - 3);
  console.log("EXT:" + ext);
  if (ext != ".rb" && ext != ".sh" && ext != ".js" && name[0] != ".") {
    if (path.slice(0,2) == "./")
      path = path.slice(2,1000);
    map[name] = path;
    count = count + 1;
  }
});

fs.writeFileSync('model_index.json', JSON.stringify(map, null, 4));
console.log("Index created with " + count + " entries");

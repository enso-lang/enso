module Plugin

import util::IDE;
import ParseTree;
extend core::lang::\syntax::EnsoLanguage;
import core::lang::\syntax::Compile;
import core::lang::\syntax::JS2Text;
import IO;
import Message;

public loc root = |project://Enso/src|;

loc jsFile(loc src) {
 rp = root.path;
 if (/^<rp>\/<rest:.*>$/ := src.path) {
   return (root + "js" + rest)[extension="js"];
 }
 return src.path[extension="js"];
}


void main() {
  registerLanguage("EnsoRuby", "rb", Tree(str src, loc org) {
    return parse(#start[Unit], src, org);
  });
  registerContributions("EnsoRuby", {
    builder(set[Message] (Tree tree) {
      if (Unit u := tree.top) {
        <ast, msgs> = compileUnit(u);
        println("Output to: <jsFile(tree@\loc)>");
        writeFile(jsFile(u@\loc), js2txt(ast));
      	return msgs;
      }
      return {error("BUG: Not a proper unit", tree@\loc)};
    })
  });
}



module core::lang::\syntax::IDE

import util::IDE;
import ParseTree;
extend core::lang::\syntax::EnsoLanguage;
import core::lang::\syntax::Compile;
import core::lang::\syntax::JS2Text;
import IO;
import Message;
import util::FileSystem;
import Ambiguity;

loc root = |project://enso/src|;

loc jsFile(loc src) {
 rp = root.path;
 if (/^<rp>\/<rest:.*>$/ := src.path) {
   return (root + "js2" + rest)[extension="js"];
 }
 return src.path[extension="js"];
}

void compileAll() {
  println("Starting");
  for (/file(loc src) := crawl(root + "core/lang/syntax/tests/")) {
    println("Compiling <src.file>...");
    pt = parse(#start[Unit], src);
    <ast, msgs> = compileUnit(pt.top);
    out = jsFile(src);
    println(" output: <out>");
    writeFile(out, js2txt(ast));
  }
}

void setup() {
  registerLanguage("Enso", "enso", Tree(str src, loc org) {
    return parse(#start[Unit], src, org);
  });
  registerContributions("Enso", {
    annotator(Tree (Tree input) {
      return input[@messages=diagnose(input)];
    }),
    builder(set[Message] (Tree tree) {
      if (Unit u := tree.top) {
        <ast, msgs> = compileUnit(u);
        println("Output to: <jsFile(tree@\loc)>");
        writeFile(jsFile(tree@\loc), js2txt(ast));
      	return msgs;
      }
      return {error("BUG: Not a proper unit", tree@\loc)};
    })
  });
}
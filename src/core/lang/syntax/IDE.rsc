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

public loc root = |project://enso/src|;

void moveToProperDirs() {
  ensos = { src | /file(loc src) := crawl(root + "/core/lang/syntax/tests") };
  rubies = { src | /file(loc src) := crawl(root), src.extension == "rb" };
  for (loc r <- rubies) {
    loc l = r[extension="enso"];
    if (loc e <- ensos, l.file == e.file) {
      s = readFile(e);
      println("Writing <l>");
      writeFile(l, s);
    }
  }
}

loc jsFile(loc src) {
 rp = root.path;
 if (/^<rp>\/<rest:.*>$/ := src.path) {
   return (root + "js2" + rest)[extension="js"];
 }
 return src.path[extension="js"];
}

list[loc] ALL_FILES = [
	|project://enso/src/core/system/boot/meta_schema.rb|,
	|project://enso/src/core/system/load/load.rb|,
	|project://enso/src/core/system/load/cache.rb|,
	|project://enso/src/core/system/utils/find_model.rb|,
	|project://enso/src/core/system/utils/paths.rb|,
	|project://enso/src/core/system/library/schema.rb|,
	|project://enso/src/core/schema/code/factory.rb|,
	|project://enso/src/core/schema/code/dynamic.rb|,
	|project://enso/src/core/schema/tools/dumpjson.rb|,
	|project://enso/src/core/schema/tools/union.rb|,
	|project://enso/src/core/schema/tools/print.rb|,
	|project://enso/src/core/schema/tools/equals.rb|,
	|project://enso/src/core/semantics/code/interpreter.rb|,
	|project://enso/src/core/grammar/render/layout.rb|,
	|project://enso/src/core/grammar/parse/sppf.rb|,
	|project://enso/src/core/grammar/parse/gss.rb|,
	|project://enso/src/core/expr/code/impl.rb|,
	|project://enso/src/core/expr/code/env.rb|,
	|project://enso/src/core/expr/code/freevar.rb|,
	|project://enso/src/core/expr/code/eval.rb|,
	|project://enso/src/core/expr/code/lvalue.rb|,
	|project://enso/src/core/expr/code/renderexp.rb|,
	|project://enso/src/core/expr/taint/proxy.rb|,
	|project://enso/src/core/diagram/code/diagram.rb|,
	|project://enso/src/core/diagram/code/stencil.rb|,
	|project://enso/src/core/diagram/code/constraints.rb|];

void compileAllSrcs() {
  for (src <- ALL_FILES) {
     compileSrc(src);
  }
}

void compileSrc(loc src) {
    try {
      println("Compiling <src.file>...");
      pt = parse(#start[Unit], src);
      <ast, msgs> = compileUnit(pt.top);
      out = jsFile(src);
      println(" output: <out>");
      writeFile(out, js2txt(ast));
      }
      catch value e: {
        println("Error <e>");
      }
}

void compileAll() {
  println("Starting");
  for (/file(loc src) := crawl(root)) {
    if (src.extension == "rb", /\/tests/ !:= src.path) {
      try {
      println("Compiling <src.file>...");
      pt = parse(#start[Unit], src);
      <ast, msgs> = compileUnit(pt.top);
      out = jsFile(src);
      println(" output: <out>");
      writeFile(out, js2txt(ast));
      }
      catch value e: {
        println("Error <e>");
      }
   }
  }
}

void setup() {
  registerLanguage("Enso", "enso", Tree(str src, loc org) {
    return parse(#start[Unit], src, org);
  });
  registerContributions("Enso", {
    annotator(Tree (Tree input) {
      return input[@messages={ m | m <- diagnose(input)}];
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
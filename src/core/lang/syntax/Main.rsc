module core::lang::\syntax::Main

import core::lang::\syntax::Compile;
import core::lang::\syntax::EnsoLanguage;
import core::lang::\syntax::JS2Text;
import IO;
import ParseTree;


void compileFile(str file) {
  loc src = |cwd:///<file>|;
  println("Compiling <src.path>...");
  start[Unit] pt;
  try {
    pt = parse(#start[Unit], src);
  }
  catch ParseError(loc err): {
    println("Parse error: <err>");
    return;
  }
  <ast, msgs> = compileUnit(pt.top);
  if (msgs != {}) {
    for (m <- msgs) {
      println(m);
    }
    return;
  }
  out = src[extension="js"];
  out = |cwd:///js/<out.path>|;
  println("output: <out>");
  writeFile(out, js2txt(ast));
}
  
  
void main(list[str] args) {
  if (args == []) {
    println("usage: ensoc.sh \<path-to-rb-file\>");
    return;
  }
  if (args[0] == "--") {
     for (str file <- args[1..]) {
       compileFile(file);
     }
     return;
  }
  compileFile(args[0]);
}
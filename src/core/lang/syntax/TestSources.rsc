module core::lang::\syntax::TestSources

extend core::lang::\syntax::EnsoLanguage;
import core::lang::\syntax::Compile;
import core::lang::\syntax::JS2Text;

import ParseTree;
import Ambiguity;
import util::FileSystem;
import IO;

void testParseSources() {
  success = 0;
  failure = 0;
  println("Starting");
  for (/file(loc src) := crawl(|project://Enso/src/core/lang/syntax/tests/|)) {
    try {
      println("Parsing <src.file>...");
      pt = parse(#start[Unit], src);
      msgs = diagnose(pt);
      //if (/amb(_) := pt) {
      if (msgs != []) {
        println("Ambiguities for <src.file>.");
        iprintln(msgs);
        failure += 1;
      }
      else {
        success += 1;
      }
    }
    catch value e: {
      println("Error for <src.file>: <e>");
      failure += 1;
    }
  }
  println("TOTAL: <success + failure>");
  println("SUCCESS: <success>");
  println("FAILURE: <failure>");
}

void testCompileSources() {
  success = 0;
  failure = 0;
  println("Starting");
  for (/file(loc src) := crawl(|project://Enso/src/core/lang/syntax/tests/|)) {
      println("Compiling <src.file>...");
      pt = parse(#start[Unit], src);
      try {
        <ast, msgs> = compileUnit(pt.top);
        if (msgs != {}) {
          iprintln(msgs);
          failure += 1;
        }
        else {
          try {
            js2txt(ast);
            success += 1;
          }
          catch value x: {
            println("Exception during unparsing: <x>");
            failure += 1;
          }
        }
      }
      catch value x: {
        println("Exception during compilation: <x>");
        failure += 1;
      }
  }
  println("TOTAL: <success + failure>");
  println("SUCCESS: <success>");
  println("FAILURE: <failure>");
}
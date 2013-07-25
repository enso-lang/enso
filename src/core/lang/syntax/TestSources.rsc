module core::lang::\syntax::TestSources

extend core::lang::\syntax::EnsoLanguage;
import ParseTree;
import Ambiguity;
import util::FileSystem;
import IO;

void testSources() {
  success = 0;
  failure = 0;
  for (/file(loc src) := crawl(|project://Enso/src/core/lang/syntax/tests|)) {
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
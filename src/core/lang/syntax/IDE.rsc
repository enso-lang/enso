module core::lang::\syntax::IDE

import util::IDE;
import ParseTree;
extend core::lang::\syntax::EnsoLanguage;

void setup() {
  registerLanguage("Enso", "enso", Tree(str src, loc org) {
    return parse(#start[Unit], src, org);
  });
}
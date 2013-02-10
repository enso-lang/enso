module Plugin

extend rsc::core::grammar::models::GrammarGrammar;
import util::IDE;
import ParseTree;


public void main() {
  registerLanguage("Grammar", "grammar", Tree(str src, loc l) {
     return parse(#start[Grammar], src, l);
  });
}
 
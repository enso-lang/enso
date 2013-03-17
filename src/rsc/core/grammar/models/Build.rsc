module rsc::core::grammar::models::Build

import rsc::core::grammar::models::Model;
import ParseTree;


list[str] extractFields(Production p) {
  return for (s <- p.symbols, \layouts(_) !:= s) {
    if (label(str n, _) := s) {
      append n;
    }
    else {
      append "";
   }
  }
} 
  

Object build(Tree pt) {
  Object owner = object("ROOT", ("root": []));
  list[Object] stack = [];
  void new(str class) {
    stack = push(owner, stack);
    owner = object(class, ());
  }
  
  void update(str fld) {
    temp = owner;
    <stack, owner> = pop(stack);
    owner.fields[fld]?[] += [temp];
  }

  void recurse(Tree pt, str field) {
      switch (pt) {
        case Tree appl(p:prod(label(str create,_ ), _, _), args): {
          new(create);
          i = 0;
          fs = extractFields(p);
          for (a <- args, appl(prod(\layouts(_), _, _),_) !:= a) {
            recurse(a, fs[i] == "" ? field : fs[i]);
            i += 1;
          }
          update(field);
        }
           
        case Tree t:appl(prod(lit(str val), _, _), _):
          if (field != "")
            owner.fields[fld]?[] += [val]; 
    
        case Tree t:appl(prod(\lex(str name), _, _), _):
            owner.fields[field]?[] += [unparse(t)]; 
      
        case Tree appl(Production p, args): {
          for (a <- args, appl(prod(\layouts(_), _, _),_) !:= a) {
            build(a, extractFields(p));
          }
        }
      }
    }
    recurse(pt, "root");
    return owner;
}
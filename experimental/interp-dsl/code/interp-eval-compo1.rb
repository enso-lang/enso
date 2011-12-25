=begin

Interp :: Schema D => forall D.forall C. {action:str, rules:Type->(D Type->C)}
Interp :: f:+:g forall D.forall C. {action:str, rules:Type->(f->C)}
compose :: pick either * or + depending on action

+ :: Interp D1 C -> Interp D2 C -> Interp (Plustype D1 D2) C
+ {action=act1, rules=rules1} {action=act1, rules=rules1} | act1=act2 =
    {action=act1, rules=concat(rules1, rules2)}

* :: Interp D C1 -> Interp D C2 -> str -> Interp D (Multype C1 C2)
* {action=act1, rules=rules1} {action=act1, rules=rules1} str =
    {action=str,
        rules=for each t in types(D), rules(t) = \args:(D t).(\act.case act=act1: rules1(t)(map \x.x(act1) args)
                                                                   case act=act2: rules2(t)(map \x.x(act2) args)
                                                             )}







Type = int | bool | str | Hashtable str Type

Schema :: Type -> Type
Schema


//Schema :: forall D. D -> Type ???? Schema is a map from a type name to a record type


  eg Schema D => D "Dog" = {name:str, num_legs:int}

  so it's like a type class but sort of first-class-ish??? aint git nuffin' buffalo pardner!

eval :: Interp D C -> D -> C



=end

require 'core/system/load/load'
require 'core/schema/tools/print'
require 'core/schema/tools/union'
require 'core/grammar/code/layout'
require 'core/interp-dsl/code/interp-type.rb'

class Interpreter

  attr_accessor :interp

  def initialize(interp)
    @interp = interp
  end

  def interpret(obj)
    type = obj.schema_class
    prepend = ""
    fields = {}
    type.fields.each do |f|
      fields[f.name] = f.type.Primitive? ? obj[f.name] : interpret(obj[f.name])
      prepend += "#{f.name} = fields[\"#{f.name}\"]\n"
    end
    Kernel::eval(prepend+@interp.rules[type.name].body.gsub('\'','"'))
  end

  def self.compose_co(name, interp1, interp2)
    if interp1.action == interp2.action
      #vertical composition
      union(interp1, interp2)
    else
      #horizontal composition
      res = Clone(interp1)
      res.action = name
      res.rules.each do |r1|
        nonprims = r1.vars.select{|v| not v.type=~/^[a-z]/}
        r2 = interp2.rules[r1.type]
        if nonprims.empty?
            r1.body = "{'#{interp1.action}' => #{r1.body} , "
            r1.body += "'#{interp2.action}' => #{r2.body} } "
        else
            r1.body = "{'#{interp1.action}' => lambda { |#{nonprims.map{|v|v.name}.join(',')}| #{r1.body}}.call(#{nonprims.map{|v| "#{v.name}['#{interp1.action}']"}.join(',')}) , \n"
            r1.body += "'#{interp2.action}' => lambda { |#{nonprims.map{|v|v.name}.join(',')}| #{r2.body}}.call(#{nonprims.map{|v| "#{v.name}['#{interp2.action}']"}.join(',')}) } "
        end
      end
      res
    end
  end

end

=begin
interesting observations:

- side effects?
- sequencing in non-side effect-free exprs (eg print))
- no shared mutable state
- no arguments

=end

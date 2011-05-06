
require 'core/schema/code/factory'
require 'core/grammar/code/implode'
require 'core/system/library/cyclicmap'
require 'core/system/boot/instance_schema'
require 'core/system/boot/schema_schema'


class Lift

  def initialize
    @factory = Factory.new(InstanceSchema.schema)
    @memo = {}
  end

  def self.lift(obj, paths = {})
    self.new.lift(obj, paths)
  end

  def lift(obj, paths)
    inst = recurse(obj, paths)
    @factory.Instances([inst])
  end


  def recurse(obj, paths={}, indent=0, visited=[])
    if obj.nil?
      return nil
    end
    visited.push obj
    klass = obj.schema_class
    inst = @factory.Instance(klass.name)
    klass.fields.each do |field|
      if field.type.Primitive?
        #puts "Adding primitive: #{obj[field.name]}"
        v = @factory.Prim(field.type.name, obj[field.name].to_s)
        inst.contents << @factory.Field(field.name, v)
      else
        sub_path = paths[field.name.to_sym]
        if sub_path || !field.inverse ||
            (!field.many && (obj[field.name].nil? || SchemaSchema.key(obj[field.name].schema_class)))
          if !field.many
            sub = obj[field.name]
            use_key = sub_path.nil? && !sub.nil? && SchemaSchema.key(sub.schema_class)
            if !visited.include?(sub) || visited[-2] != sub && use_key
              inst.contents << @factory.Field(field.name, make_1(use_key, sub, sub_path, visited))
            end
          else
            f = @factory.Field(field.name)
            l = @factory.List
            obj[field.name].each_with_index do |sub, i|
              use_key = sub_path.nil? && SchemaSchema.key(sub.schema_class)
              l.elements << make_1(use_key, sub, sub_path, visited)
            end
            f.value = l
            inst.contents << f
          end
        end
      end
    end
    visited.pop
    return inst
  end

  def make_1(use_key, obj, path, visited)
    if use_key  
      @factory.Ref(obj[SchemaSchema.key(obj.schema_class).name])
    else
      recurse(obj, path || {}, visited)
    end
  end
  
end


if __FILE__ == $0 then
  require 'core/grammar/code/parse'
  require 'core/grammar/code/layout'
  require 'core/schema/tools/print'

  require 'core/system/boot/grammar_grammar'
  obj = CPSParser.load('core/grammar/models/grammar.grammar', GrammarGrammar.grammar,
                       GrammarSchema.schema)

  p obj
  ast = Lift.lift(obj, {:rules => {}})

  Print.print(ast)

  ig = Loader.load('instance.grammar')

  DisplayFormat.print(ig, ast)

  ast2 = Lift.lift(ast)
  DisplayFormat.print(ig, ast2)

  obj = Instantiate.instantiate(Factory.new(GrammarSchema.schema), ast)
  Print.print(obj)

  DisplayFormat.print(GrammarGrammar.grammar, obj)

  
end

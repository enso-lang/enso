
require 'core/grammar/code/origins'
require 'core/grammar/code/gll/gll'
require 'core/grammar/code/gll/implode'
require 'core/instance/code/instantiate'
require 'core/schema/tools/print'

class Parse

  def self.load_file(path, grammar, schema)
    load(File.read(path), grammar, schema, path)
  end
  
  def self.load(source, grammar, schema, filename = '-')
    data = load_raw(source, grammar, schema, Factory.new(schema), false, filename)
    return data.finalize
  end
  
  def self.load_raw(source, grammar, schema, factory, show = false, filename = '-')
    org = Origins.new(source, filename)
    tree = parse(source, grammar, org)
    inst = Implode.implode(tree, org)
    Print.print(inst) if show
    Instantiate.instantiate(factory, inst)
  end

  def self.parse(source, grammar, org)
    GLL.parse(source, grammar, grammar.start, org)
  end
  
end

if __FILE__ == $0 then
  require 'core/system/load/load'
  require 'core/grammar/code/layout'
  ig = Loader.load('instance.grammar')
  grammar = Loader.load('schema.grammar')
  
  path = 'applications/ToDo/models/todo.schema'
  source = File.read(path)
  org = Origins.new(source, path)
  tree = Parse.parse(source, grammar, org)
  inst = Implode.implode(tree, org)

  puts "Referenced in start: #{ig.start._origin}"
  puts "Reference 'start': #{ig._origin_of.start}"

  is = Loader.load('web.schema')
  
  puts "Instances: #{is.classes['Web']._origin}"
#  puts "Reference 'start': #{ig._origin_of.start}"

  #DisplayFormat.print(ig, inst)
end


require 'core/grammar/code/gll/gll'
require 'core/grammar/code/gll/implode'
require 'core/instance/code/instantiate'
require 'core/schema/tools/print'

class Parse

  def self.load_file(path, grammar, schema)
    load(File.read(path), grammar, schema)
  end
  
  def self.load(source, grammar, schema)
    data = load_raw(source, grammar, schema, Factory.new(schema))
    return data.finalize
  end
  
  def self.load_raw(source, grammar, schema, factory, show = false)
    tree = parse(source, grammar)
    inst = Implode.implode(tree)
    Print.print(inst) if show
    Instantiate.instantiate(factory, inst)
  end

  def self.parse_file(grammar)
    parse(path, File.read(path), grammar)
  end
  
  def self.parse(source, grammar)
    GLL.parse(source, grammar)
  end
  
end

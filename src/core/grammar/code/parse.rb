
require 'core/grammar/code/gll/gll'
require 'core/grammar/code/gll/implode'
require 'core/instance/code/instantiate'

class Parse

  def self.load_file(path, grammar, schema)
    load(File.read(path), grammar, schema)
  end
  
  def self.load(source, grammar, schema)
    data = load_raw(source, grammar, schema, Factory.new(schema))
    return data.finalize
  end
  
  def self.load_raw(source, grammar, schema, factory)
    tree = parse(source, grammar)
    Instantiate.instantiate(factory, Implode.implode(tree))
  end

  def self.parse_file(grammar)
    parse(path, File.read(path), grammar)
  end
  
  def self.parse(source, grammar)
    GLL.parse(source, grammar)
  end
  
end

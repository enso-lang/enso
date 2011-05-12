
require 'core/grammar/code/gll/gll'
require 'core/grammar/code/gll/implode'
require 'core/instance/code/instantiate'

class Parse


  def self.load_file(path, grammar, schema)
    load(File.read(path), grammar, schema)
  end
  
  def self.load(source, grammar, schema)
    data = load_raw(source, grammar, schema)
    data.finalize
    return data
  end
  
  def self.load_raw(source, grammar, schema)
    tree = parse(source, grammar)
    Instantiate.instantiate(Factory.new(schema), Implode.implode(tree))
  end

  def self.parse_file(grammar)
    parse(path, File.read(path), grammar)
  end
  
  def self.parse(source, grammar)
    GLL.parse(source, grammar)
  end
  
end

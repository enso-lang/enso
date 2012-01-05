
require 'core/grammar/parse/origins'
require 'core/grammar/parse/gll'
require 'core/grammar/parse/build'
#require 'core/grammar/parse/ast'
require 'core/schema/tools/print'
require 'core/schema/code/factory2'

class Parse

  def self.load_file(path, grammar, schema, encoding = nil)
    if encoding then
      File.open(path, 'r', :encoding => encoding) do |f|
        src = f.read
        return load(src, grammar, schema, path)
      end
    else
      load(File.read(path), grammar, schema, path)
    end
  end
  
  def self.load(source, grammar, schema, filename = '-')
    data = load_raw(source, grammar, schema, ManagedData::Factory.new(schema), false, filename)
    return data.finalize
  end
  
  def self.load_raw(source, grammar, schema, factory, show = false, filename = '-')
    org = Origins.new(source, filename)
    tree = parse(source, grammar, org)
    Print.print(inst) if show
    Build.build(tree, factory, org)
  end

  def self.parse(source, grammar, org)
    GLL.parse(source, grammar, grammar.start, org)
  end
  
end

if __FILE__ == $0 then
  require 'core/system/load/load'
  require 'core/schema/code/factory2'
  require 'benchmark'
  require 'ruby-prof'
  grammar = Loader.load('web.grammar')
  ss = Loader.load('web.schema')
  factory = ManagedData::Factory.new(ss)
  path = 'core/web/models/prelude.web'
  source = File.read(path)
  org = Origins.new(source, path)
  
  puts "PARSING"
  tree = nil

  10.times do |x|
    puts Benchmark.measure { tree = Parse.parse(source, grammar, org) }
  end

  result = RubyProf.profile do 
    Build.build(tree, factory, org)
  end

  printer = RubyProf::FlatPrinter.new(result)
  printer.print(STDOUT, {})



#   puts "BUILDING"
#   10.times do |x|
#     puts Benchmark.measure { Build.build(tree, factory, org) }
#   end
  

end

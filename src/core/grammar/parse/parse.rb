
require 'core/grammar/parse/origins'
require 'core/grammar/parse/gll'
require 'core/grammar/parse/build'
require 'core/schema/tools/print'
require 'core/schema/code/factory'

class Parse

  def self.load_file(path, grammar, schema, encoding = nil)
    if encoding then
      File.open(path, 'r', encoding: encoding) do |f|
        src = f.read
        return load(src, grammar, schema, path)
      end
    else
      load(File.read(path), grammar, schema, path)
    end
  end
  
  def self.load(source, grammar, schema, filename = '-')
    #TODO: need a better way to parse imports
    imports = []
    s = source.split("\n")+[""] #this is to ensure i is correct for 'empty' files with only imports
    for i in 0..s.length-1
      next if s[i].strip.length==0
      break unless s[i].strip.start_with? 'import'
      files = s[i].gsub(' ','')[6..-1].split(',')
      files.each do |f|
        imports << f
      end
    end
    source = s[i..-1].join("\n")
    data = load_raw(source, grammar, schema, Factory::new(schema), false, filename)
    imports.each do |imp|
      $stderr << "## importing #{imp}...\n" 
      u = Load::load(imp)
      data = Union::union(u, data)
      FindModel::FindModel.find_model(imp) {|p| data.factory.file_path << p}
    end
    data.factory.file_path.unshift(filename)
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
  require 'core/schema/code/factory'
  require 'benchmark'
  require 'ruby-prof'
  grammar = Load::load('web.grammar')
  ss = Load::load('web.schema')
  factory = Factory::new(ss)
  path = 'apps/web/models/prelude.web'
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

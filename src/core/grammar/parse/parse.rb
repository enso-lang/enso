
require 'core/grammar/parse/origins'
require 'core/grammar/parse/gll'
require 'core/grammar/parse/build'
require 'core/schema/tools/print'
require 'core/schema/code/factory'
require 'core/grammar/tools/rename_binding'

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
    imports = {}
    s = source.split("\n")+[""] #this is to ensure i is correct for 'empty' files with only imports
    imps = nil
    deps = [filename]
    for i in 0..s.length-1
      next if s[i].lstrip.empty?
      if s[i] =~ /import (?<file>\w+.\w+)( with(?<as>( \w+ as \w+)+))?/
        imp = $1; as = $2
        FindModel::FindModel.find_model(imp) {|p| deps << p}

        $stderr << "## importing #{imp}...\n"
        u = Load::load(imp)
        if as 
          if imp.split('.')[1]=="schema" #we only know how to rename schemas right now
            u = Union::Copy(Factory::SchemaFactory.new(Load::load('schema.schema')), u)
            as.split(' ').select{|x|x!="as"}.each_slice(2) do |from, to|
              rename_schema!(u, from, to)
            end
          elsif imp.split('.')[1]=="grammar"
            as.split(' ').select{|x|x!="as"}.each_slice(2) do |from, to|
              rename_binding!(u, {from=>to})
            end
          end
        end
        if imps.nil?
          imps = u
        else
          imps = Union::union(u, imps)
        end
        puts "imps=#{imps}"
      else
        break;
      end
    end
    source = s[i..-1].join("\n")
    data = load_raw(source, grammar, schema, Factory::new(schema), imps, false, filename)
    deps.each {|p| data.factory.file_path << p}
    return data.finalize
  end

  def self.rename_schema!(schema, from, to)
    x = schema.types[from]
    x.name = to
    schema.types._recompute_hash!
  end

  def self.load_raw(source, grammar, schema, factory, imports=nil, show = false, filename = '-')
    org = Origins.new(source, filename)
    tree = parse(source, grammar, org)
    Print.print(inst) if show
    Build.build(tree, factory, org, imports)
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

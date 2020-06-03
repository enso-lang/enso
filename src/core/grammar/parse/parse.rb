
require 'core/grammar/parse/origins'
require 'core/grammar/parse/gll'
#require 'core/grammar/parse/enso-gll'
#require 'core/grammar/parse/enso-build'
require 'core/grammar/parse/build'
require 'core/schema/tools/print'
require 'core/schema/code/factory'
require 'core/grammar/tools/rename_binding'
# require 'debugger'

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
    #handle imports
    s = source.split("\n")+[""] #this is to ensure i is correct for 'empty' files with only imports
    deps = [filename]
    schema.factory.file_path.each  {|p| deps << p}
    imports = []
    # scan each line from the top of the file looking for 'import'
    for i in 0..s.length-1
      next if s[i].lstrip.empty?
      if s[i] =~ /import (?<file>\w+.\w+)( with(?<as>( \w+ as \w+)+))?/
        imp = $1; as = $2
        $stderr << "## importing #{imp}...\n" 
        u = Load::load(imp)
        u.factory.file_path.each  {|p| deps << p}
        if as 
          if imp.split('.')[1]=="schema" #we only know how to rename schemas and grammars right now
            u = Union::Copy(Factory::SchemaFactory::SchemaFactory.new(Load::load('schema.schema')), u)
            as.split(' ').select{|x|x!="as"}.each_slice(2) do |from, to|
              rename_schema!(u, from, to)
            end
          elsif imp.split('.')[1]=="grammar"
            as.split(' ').select{|x|x!="as"}.each_slice(2) do |from, to|
              rename_binding!(u, {from=>to})
            end
          end
        end
        imports.unshift(u)
      else
        break;
      end
    end
    source = "\n"*i+s[i..-1].join("\n") #replace import lines from source with blanks
                                        # do not simply remove as this messes up source line numbers
    data = load_raw(source, grammar, schema, Factory::SchemaFactory.new(schema), imports, false, filename)
    deps.uniq.each {|p| data.factory.file_path << p}
    return data.finalize
  end

  def self.rename_schema!(schema, from, to)
    x = schema.types[from]
    x.name = to
    schema.types._recompute_hash!
  end

  def self.load_raw(source, grammar, schema, factory, imports = [], show = false, filename = '-')
    org = Origins.new(source, filename)
    tree = parse(source, grammar, org)
    # File.open('sppf.dot', 'w') do |f|
    #   ToDot.to_dot(tree, f)
    # end
    Print.print(inst) if show
    if ENV['GLL'] == 'enso' then
      puts "BUILD_GLL"
      EnsoBuild::build(tree, factory, org, imports)
    else
      Build.build(tree, factory, org, imports)
    end
  end

  def self.parse(source, grammar, org)
    if ENV['GLL'] == 'enso' then
      EnsoGLL::parse(source, grammar, org)
    else
      GLL.parse(source, grammar, grammar.start, org)
    end
  end
  
end


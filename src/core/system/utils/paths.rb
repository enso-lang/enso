

module Paths

  class Path
    attr_reader :elts

    def self.parse(str)
      if str.empty?
        Path.new
      elsif str =~ /^\.(.*)$/ then
        Path.new([Current.new] + parse($1).elts)
      elsif str =~ /^\/([a-zA-Z_0-9]+)(.*)$/ then
        Path.new([Field.new($1)] + parse($2).elts)
      elsif str =~ /^\[([0-9]+)\](.*)$/ then
        Path.new([Index.new($1.to_i)] + parse($2).elts)
      elsif str =~ /^\[((((?=\\)[\[\]])|[^\[\]])+)\](.*)$/  then
        rest = $4
        s = $1.gsub('\\[', '[]').gsub('\\]',  ']')
        Path.new([Key.new(s)] + parse(rest).elts)
      else
        raise "Cannot parse path: '#{str}'"
      end
    end

    def initialize(elts = [])
      @elts = elts
    end

    def reset!
      @elts = []
    end

    def prepend!(path)
      @elts = path.elts + @elts
    end

    def extend(path)
      Path.new(elts + path.elts)
    end

    def deref(root, this = root)
      elts.each do |elt|
        n = elt.deref(root, this)
        raise "\n#{root} does not have component #{elt}" if !n
        root = n
      end
      root
    end

    def field(name)
      descend(Field.new(name))
    end
    
    def key(key)
      descend(Key.new(key))
    end

    def index(index)
      descend(Index.new(index))
    end

    def root?
      elts.empty?
    end

    def lvalue?
      !root? && last.is_a?(Field)
    end

    def assign(root, obj)
      raise "Can only assign to lvalues not to #{self}" if not lvalue?
      owner.deref(root)[last.name] = obj
    end

    def assign_and_coerce(root, value)
      raise "Can only assign to lvalues not to #{self}" if not lvalue?
      obj = owner.deref(root)
      fld = obj.schema_class.fields[last.name]
      if fld.type.Primitive? then
        value = 
          case fld.type.name 
          when 'str' then value.to_s
          when 'int' then value.to_i
          when 'bool' then (value.to_s == 'true') ? true : false
          when 'real' then value.to_f
          else
            raise "Unknown primitive type: #{fld.type.name}"
          end
      end
      owner.deref(root)[last.name] = value
    end

    def insert(root, obj)
      deref(root) << obj
    end

    def insert_at(root, key, obj)
      deref(root)[key] = obj
    end

    def owner
      Path.new(elts[0..-2])
    end    
    
    def last
      elts.last
    end

    def to_s
      elts.join
    end

    private
    
    def descend(elt)
      Path.new([*elts, elt])
    end
  end

  ROOT = Path.new


  class Elt
    # path element
  end

  class Current < Elt
    def deref(obj, this)
      this
    end

    def to_s
      '.'
    end
  end

  class Field < Elt
    attr_reader :name

    def initialize(name)
      @name = name
    end

    def deref(obj, root)
      obj[@name]
    end

    def to_s
      "/#{@name}"
    end
  end

  class Index < Elt
    def initialize(index)
      @index = index
    end

    def deref(obj, root)
      obj[@index]
    end

    def to_s
      "[#{@index}]"
    end
  end


  class Key < Elt
    def initialize(key)
      @key = key
    end

    def deref(obj, root)
      obj[@key]
    end

    def to_s
      "[#{escape(@key.to_s)}]"
    end

    private

    def escape(s)
      s.gsub(']', '\\]').gsub('[', '\\[')
    end
  end


end

if __FILE__ == $0 then
  def print(obj)
    obj.schema_class.fields.each do |fld|
      if fld.type.Primitive? then
        puts "#{obj._path}.#{fld.name} = #{obj[fld.name].inspect}"
      elsif fld.many then
        obj[fld.name].each do |x|
          puts "#{obj._path}.#{fld.name} = #{x._path}"
        end
      else
        if obj[fld.name] then
          puts "#{obj._path}.#{fld.name} = #{obj[fld.name]._path}"
        else
          puts "#{obj._path}.#{fld.name} = nil"
        end
      end
      if !fld.many && fld.traversal && !fld.type.Primitive? then
        print(obj[fld.name])
      end
      if fld.many && fld.traversal then
        obj[fld.name].each do |x|
          print(x)
        end
      end
    end
  end
  
  require 'core/system/load/load'
  ss = Loader.load('schema.schema')
  ss = Loader.load('grammar.grammar')
  ss = Loader.load('test.todo')
  print(ss)
end


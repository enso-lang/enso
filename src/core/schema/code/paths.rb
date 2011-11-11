

module Paths
  class Path
    attr_reader :elts

    def initialize(elts = [])
      @elts = elts
    end

    def reset!
      @elts = []
    end

    def prepend!(path)
      @elts = path.elts + @elts
    end

    def field(fld)
      descend(Field.new(fld))
    end
    
    def key(key)
      descend(Key.new(key))
    end

    def index(index)
      descend(Index.new(index))
    end

    def root?
      elts == []
    end

    def to_s
      elts.join
    end

    private
    
    def descend(elt)
      Path.new([*elts, elt])
    end
  end


  class Elt
    # path element
  end

  class Field < Elt
    def initialize(field)
      @field = field
    end

    def to_s
      ".#{@field.name}"
    end
  end

  class Index < Elt
    def initialize(index)
      @index = index
    end

    def to_s
      "[#{@index}]"
    end
  end

  class Key < Elt
    def initialize(key)
      @key = key
    end

    def to_s
      s = @key.to_s.gsub('}', '\\}').gsub('{', '\\{')
      "{#{s}}"
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
  print(ss)
end


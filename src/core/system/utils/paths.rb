
# TODO: error handling

module Paths
  def self.parse(str)
    p = Path.parse(str)
    #puts "PARSE #{str} #{p}"
    p
  end

  def self.new(elts = [])
    Path.new(elts)
  end

  class Path
    attr_reader :elts

    def self.parse(str)
      original = str
      str = str.gsub("\\", "")
      if str[0] == "/"
        str = str.slice(1,1000)
        base = [Root.new]
      else
        base = []
      end
      elts = base.concat(scan(str))
      #puts "PARSE '#{original}' #{elts}"
      Path.new(elts)
    end
    
    def self.scan(str)
      result = []
      str.split("/").each do |part|
        if (n = part.index("[")) && part.slice(-1) == "]"
          base = part.slice(0, n)
          index = part.slice(n+1, part.length - n - 2)
          result << Field.new(base)
          result << Key.new(index)
        elsif part != "."
          result << Field.new(part)
        end
      end
      result
    end

    def initialize(elts = [])
      @elts = elts
    end
    
#    def ==(other)
#      to_s == other.to_s
#    end

    def reset!
      @elts = []
    end

    def prepend!(path)
      @elts = path.elts + @elts
    end

    def extend(path)
      Path.new(elts + path.elts)
    end

    def deref?(scan, root = scan)
      begin
        deref(scan, root = scan)
      rescue
        false
      end
    end

    def deref(scan, root = scan)
      #puts "Deref element: #{elts}, scan = #{scan}, root=#{root}"
      elts.each do |elt|
        raise "cannot dereference #{elt} on #{scan}" if !scan
        scan = elt.deref(scan, root)
      end
      scan
    end

    def search(root, base, target)
      #puts "SEARCH_START #{root} #{base} #{target}"
      searchElts(elts, base, root, {}) do |item, bindings|
        #puts "SEARCH #{elts} ==> #{item} for #{target} with #{bindings} (#{target.equals(item)})"
        bindings if target.equals(item)
      end
    end

    def searchElts(todo, scan, root, bindings, &action)
      #puts "SEARCH_ELTS #{todo} on #{scan} with #{bindings}"
      if todo.nil? || todo.first.nil?
        action.call(scan, bindings)
      else
        todo.first.search(scan, root, bindings) do |item, newBinds|
          searchElts(todo[1..-1], item, root, newBinds, &action)
        end
      end
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
      res = elts.join
      res=="" ? "/" : res
    end

    #private
    
    def descend(elt)
      Path.new([*elts, elt])
    end
  end

  ##ROOT = Path.new


  class Elt
    # path element
  end

  class Root < Elt
    def deref(obj, root)
      #puts "Derreffing 'this': obj = #{obj}; root = #{root}"
      root
    end

    def search(obj, root, bindings, &action)
      action.call(root, bindings)
    end

    def to_s
      'ROOT'
    end
  end

  class Field < Elt
    attr_reader :name
    #alias :value :name

    def initialize(name)
      @name = name
    end

    def deref(obj, root)
      obj[@name]
    end

    def search(obj, root, bindings, &action)
      #puts "SEARCH_FIELD #{obj}.#{@name} => #{obj[@name]}"
      action.call(obj[@name], bindings) if !obj.nil? && obj.schema_class.all_fields[@name]
    end

    def to_s
      "/#{@name}"
    end
  end

  class Index < Elt
    attr_reader :index
    #alias :value :index

    def initialize(index)
      @index = index
    end

    def deref(obj, root)
      obj[@index]
    end

    def search(obj, root, bindings, &action)
      #puts "SEARCH_INDEX #{obj} root=#{root} binds=#{bindings}"
      if @index.is_a?(PathVar)
        obj.find_first_with_index do |item, i|
          action.call(item, { it: i}.update(bindings))
        end
      else
        action.call(obj[@index], bindings)
      end
    end

    def to_s
      "[#{@index}]"
    end
  end


  class Key < Elt
    attr_reader :key
    #alias :value :key

    def initialize(key)
      @key = key
    end

    def deref(obj, root)
      obj[@key]
    end

    def search(obj, root, bindings, &action)
      if @key.is_a?(PathVar)
        #puts "SEARCH_KEY #{obj} root=#{root} binds=#{bindings}"
        obj.find_first_pair do |k, item|
          action.call(item, { it: k}.update(bindings))
        end
      else
        action.call(obj[@key], bindings)
      end
    end

    def to_s
      "[#{escape(@key.to_s)}]"
    end

    #private

    def escape(s)
      s.gsub(']', '\\]').gsub('[', '\\[')
    end
  end
  
  class PathVar
    def initialize(name)
      @name = name
    end
    attr_reader :name
    def to_s
      @name
    end
  end
end


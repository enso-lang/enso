
require 'core/web/code/web'

module Web::Eval

  class Value
    def self.parse(v)
      if v =~ /^[@.]/ then
        Ref.make(v)
      elsif v.is_a?(Array) then
        v.map { |x| Ref.make(x) }
      else
        Value.new(v)
      end
    end

    def initialize(value)
      puts "MAKING VALUE: #{value} #{value.class}"
      @value = value
    end

    def value(root, store)
      @value
    end

    def result(root, store)
      Result.new(value(root, store))
    end

    def to_s
      @value.to_s
    end
  end

  class PathElt 
    attr_reader :key

    def initialize(key)
      @key = key
    end

    def update!(obj, rvalue)
      fld = obj.schema_class.fields[key]
      if fld.many then
        obj[key] << rvalue
      else
        obj[key] = convert(fld, rvalue)
      end
    end

    private

    def convert(field, value)
      if field.type.Primitive? then
        case  field.type.name 
        when 'int' 
          Integer(value)
        when 'bool'
          value == 'true'
        when 'real'
          Float(value)
        when 'str'
          value
        end
      else
        # LValue.update already has deref'fed any paths.
        value
      end
    end

  end

  class Key < PathElt
    def to_s
      "[#{key}]"
    end
  end

  class Field < PathElt
    def to_s
      ".#{key}"
    end
  end

  class New < PathElt
    def to_s
      key
    end
  end

  class Ref
    attr_reader :path

    def self.make(str)
      self.new(parse(str))
    end

    def self.parse(value)
      value = value[1..-1] if value =~ /^\./
      value.split(/\./).flat_map do |x|
        if x =~ /^(.*)\[(.*)\]$/ then
          fld = $1
          key = $2
          key = Integer(key) if key =~ /^[0-9]+$/
          puts "MAKING fld + key: #{fld} [#{key}]"
          [Field.new(fld), Key.new(key)]
        elsif x =~ /^@/ then
          puts "MAKING NEW: #{x}"
          New.new(x)
        else
          puts "MAKING FIELD: #{x}"
          Field.new(x)
        end
      end
    end

    def initialize(path)
      @path = path
    end

    def value(root, store)
      deref(root, store)
    end

    def result(root, store)
      Result.new(value(root, store), self)
    end

    def ==(o)
      path == o.path
    end

    def descend_collection(key)
      Ref.new([*path, Key.new(key)])
    end

    def descend_field(key)
      Ref.new([*path, Field.new(key)])
    end

    def var?
      path.length == 1
    end

    def name
      # assert var?
      path.first
    end

    def deref(root, store)
      path.inject(root) do |cur, x|
        lookup(cur, x, store)
      end
    end

    def to_s
      path.join
    end

    def lookup(owner, path_elt, store)
      puts "---------- looking up: #{path_elt} in #{owner}"
      if Store.new?(path_elt.key) then
        store[path_elt.key]
      else
        owner[path_elt.key]
      end
    end
  end


  class LValue < Ref

    def update(rvalue, root, store)
      *base, fld = path
      puts "UPDATING: #{base.join('.')} #{fld} to #{rvalue}"
      owner = base.inject(root) do |cur, x|
        lookup(cur, x, store)
      end
      fld.update!(owner, rvalue.value(root, store))
    end

  end

end

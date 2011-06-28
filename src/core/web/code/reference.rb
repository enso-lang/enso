
require 'core/web/code/web'

module Web::Eval
  class Assignable
  end

  class Value < Assignable
    def initialize(value)
      @value = value
    end

    def value(root, store)
      @value
    end

    def result(root, store)
      Result.new(value(root, store))
    end
  end

  class PathElt 
    attr_reader :key

    def initialize(key)
      @key = key
    end

  end

  class Key < PathElt
    def to_s
      "[#{key}]"
    end

    def update!(obj, rvalue)
      obj[key] << rvalue
    end
  end

  class Field < PathElt
    def to_s
      ".#{key}"
    end

    def update!(obj, rvalue)
      obj[key] = rvalue
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
      value.split(/\./).flat_map do |x|
        if x =~ /^(.*)\[(.*)\]$/ then
          key = $2
          key = Integer(key) if key =~ /^[0-9]+$/
          [Field.new($1), Key.new(key)]
        elsif x =~ /^@/ then
          New.new(x)
        else
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
      fld.update!(owner, rvalue)
    end

  end

end

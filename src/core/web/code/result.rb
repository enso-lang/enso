
require 'core/web/code/web'
require 'uri'

module Web::Eval
  # "Results" model computed values
  # The environment binds names to results.

  class Result
    attr_reader :value

    def self.parse(v, root)
      if v =~ /^[.]/ then
        Ref.parse(v, root)
      elsif v =~ /^@/
        New.parse(v, root)
      elsif v.is_a?(Array) then
        List.new(v.map { |x| parse(x, root) })
      else
        # TODO: how to know if a value is int or str or real?
        Result.new(v)
      end
    end

    def initialize(value)
      @value = value
    end

    def render
      value.to_s
    end

    def truthy?
      value
    end

    def to_s
      "#{self.class.name}(#{value})"
    end

    def inspect
      to_s
    end
  end

  class List < Result
    include Enumerable

    def initialize(elts)
      # NB: elts are results
      @elts = elts
    end

    def each(&block)
      @elts.each(&block)
    end

  end

  class Record < Result
    # does not support nesting of records.
    # in values in value map are results.

    def field(n)
      value[n] || Result.new(nil)
    end

    def subscript(k)
      value[k] || Result.new(nil)
    end

    def to_s
      "record(#{value.keys})"
    end
  end

  class Ref < Result
    attr_reader :path, :root

    # a "value" passed by reference.
    
    def self.parse(str, root)
      path = Paths::Path.parse(str)
      value = path.deref(root)
      Ref.new(value, path, root)
    end

    def initialize(value, path, root)
      super(value)
      @path = path
      @root = root
    end

    def field(n)
      Ref.new(value[n], path.field(n), root)
    end

    def subscript(k)
      Ref.new(value[k], path.key(k), root)
    end
    
    def address
      Address.new(path)
    end

    def factory
      value._graph_id
    end

    def each_with_index
      value.each_with_index do |v, i|
        key_field = ClassKey(v.schema_class)
        key = key_field ? v[key_field.name] : i
        yield subscript(key), key
      end
    end

    def assign(x)
      # only for non-many a.x or a[x] refs
      path.assign(root, x)
    end
    
    def insert(x)
      # only for many-list a.x refs
      path.insert(root, x)
    end
    
    def insert_at(key, x)
      # only for many-list and many-keyed a[x] refs
      path.insert_at(root, key, x)
    end
    
    def to_s
      "ref(#{path}, #{value})"
    end
  end
  
  
  class Address < Result
    def render
      value.to_s
    end

    def to_s
      "address(#{render})"
    end
  end

  class New < Ref
    attr_reader :id

    # TODO: use weakrefs in the table
    @@ids = 0
    @@table = {}

    def self.parse(str, root)
      if str =~ /^@([a-zA-Z_][a-zA-Z0-9_]*):([0-9]+)(.*)$/ then
        new($1, root, $2.to_i)
      else
        raise "Could not parse New: #{str}"
      end
    end


    def self.new(klass, root, id = nil)
      if id.nil? then
        id = @@ids += 1
      end
      @@table[id] ||= root._graph_id[klass]
      super(@@table[id], Paths::ROOT, root, klass, id)
    end

    def initialize(value, path, root, klass, id)
      super(value, path, root)
      @klass = klass
      @id = id
    end

    def render
      "@#{@klass}:#{id}"
    end

  end
  
  class Call < Result
    attr_reader :args

    def initialize(appl, args = nil)
      super(appl)
      @args = args
    end

    def bind(args)
      self.class.new(value, args)
    end

    def to_s
      "call(#{value}, #{args})"
    end

  end

  class Action < Call
    SEP = '##'

    # At rendering time this class models
    # hidden input fields that represent actions
    # that should be executed upon submit.
    # During a post request, these action calls are 
    # recovered from the form data and executed after
    # data binding has been completed.
    # This class wraps (ordinary) Ruby methods.
    # Furthermore, the purpose of this class is:
    # - providing encoding to render an action as a hidden 
    #   input field
    # - actually executing the action

    def self.parse(key, value, env, root)
      if key =~ /^!([^?]+)/ then
        method = env[$1] # should resolve to action
      end
      if key =~ /\?(.+)$/ then
        cond = $1
      end
      args = value.split(SEP).map do |x|
        Result.parse(x, root)
      end
      Action.new(method, args, cond)
    end

    def initialize(method, args = nil, cond = nil)
      super(method, args)
      @cond = cond
    end

    def render_key(cond)
      "!#{value.name}#{cond && ('?' + cond)}"
    end

    def render_args
      args.map do |arg|
        arg.render # todo escape SEP
      end.join(SEP)
    end

    def to_s
      "#{render_key(@cond)}:#{args && render_args}"
    end
    
  end

  class Template < Call
    # This class wraps enso-web functions/closures.
    # Its purpose is dual:
    # - representing calls to be rendered as URLs
    # - invoking template functions during rendering

    def render
      params = []
      value.formals.each_with_index do |f, i|
        arg = URI.escape(args[i].render)
        params << "#{f.name}=#{arg}"
      end
      params.empty? ? value.name : "#{value.name}?#{params.join('&')}" 
    end

    def invoke(eval, env, out, errors)
      eval.eval(value.body, env, out, errors)
    end

  end
  
end


require 'core/web/code/web'
require 'uri'

module Web::Eval
  # "Results" model computed values
  # The environment binds names to results.

  class Result
    attr_reader :value

    def self.parse(v, root)
      if v =~ /^[.@]/ then
        Ref.parse(v, root)
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
    
    class NewPath
      attr_reader :store, :klass, :id

      def initialize(klass, id, store)
        @klass = klass
        @id = id
        @store = store
      end

      def deref(root)
        # ignore the root, but look in store
        store[id]
      end

      def to_s
        "@#{klass}:#{id}"
      end

    end

    @@id = 0
    @@store = {}

    def self.create(klass, root, id = nil)
      if id.nil? then
        id = @@id += 1
      end
      @@store[id] ||= root._graph_id[klass]
      start = NewPath.new(klass, id, @@store)
      path = Paths::Path.new([start])
      Ref.new(@@store[id], path, root)
    end

    def self.parse(str, root)
      if str =~ /^@([a-zA-Z_][a-zA-Z0-9_]*):([0-9]+)(.*)$/ then
        create($1, root, $2).extend(Paths::Path.parse($3))
      else
        path = Paths::Path.parse(str)
        value = path.deref(root)
        Ref.new(value, path, root)
      end
    end

    def initialize(value, path, root)
      super(value)
      @path = path
      @root = root
    end

    def extend(nxt)
      Ref.new(nxt.deref(value), path.extend(nxt), root)
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
      path.assign(root, x.value)
    end
    
    def to_s
      "ref(#{path}, #{value})"
    end

    def render
      # TODO: maintain the type of this reference to avoid
      # this "heuristic"
      if value.respond_to?(:schema_class) then
        # NB: use the canonical path if possible
        if !value._path.root? then
          puts "CANONICAL------> #{value._path}"
          value._path.to_s
        else
          path.to_s
        end
      elsif value.respond_to?(:each)
        path.to_s
      else
        super
      end
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

    attr_reader :cond

    #alias value method

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
        action = env[$1] # should resolve to action
      end
      if key =~ /\?(.+)$/ then
        cond = $1
      end
      args = value.split(SEP).map do |x|
        Result.parse(x, root)
      end
      Action.new(action.value, args, cond)
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

    def invoke(env)
      if !cond || (cond && env[cond]) then
        value.call(*args)
      end
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

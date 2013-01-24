
require 'core/web/code/web'
require 'uri'

module Web::Eval
  # "Results" model computed values
  # The environment binds names to results.

  class Result
    attr_reader :value

    def self.parse(v, root, env)
      # TODO: now templates are amb with paths...
      if v =~ /^\^/ then
        Ref.parse(v, root, env)
      elsif v =~ /^\// then
        Template.parse(v, root, env)
      elsif v.is_a?(Array) then
        List.new(v.map { |x| parse(x, root, env) })
      else
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
      value.inspect
    end
  end

  class List < Result
    include Enumerable

    # NB: value contains results

    def each(&block)
      value.each(&block)
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
    # a "value" passed by reference.

    attr_reader :path, :root
    
    class NewPath
      # this class implements a special path element
      # that is used to start paths of newly created
      # objects

      attr_reader :store, :klass, :id, :obj

      def initialize(klass, id, store, obj)
        @klass = klass
        @id = id
        @store = store
        @obj = obj
      end

      def deref(obj, root)
        # ignore the root, but look in store
        store[id]
      end

      def to_s
        if obj._path.root? then
          "@#{klass}:#{id}"
        else
          obj._path.to_s
        end
      end
    end

    @@id = 0
    @@store = {} # TODO: use weakrefs

    def self.create(klass, root, id = nil)
      if id.nil? then
        id = @@id += 1
      end
      obj = @@store[id] ||= root._graph_id[klass]
      start = NewPath.new(klass, id, @@store, obj)
      path = Paths.new([start])
      Ref.new(obj, path, root)
    end

    def self.parse(str, root, env)
      str = str[1..-1] # skip initial ^
      if str =~ /^@([a-zA-Z_][a-zA-Z0-9_]*):([0-9]+)(.*)$/ then
        create($1, root, $2).extend(Paths.parse($3))
      else
        path = Paths.parse(str)
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
      # TODO: it feels wrong to coerce primitives
      # to string values; yet it only happens 
      # when binding (when everything non-object
      # is a string anyway.
      path.assign_and_coerce(root, x.value)
    end
    
    def to_s
      "ref(#{path}, #{value})"
    end

    def render
      # TODO: maintain the type of this reference 
      # to avoid this "heuristic"
      if value.respond_to?(:schema_class) then
        "^#{path}"
      elsif value.respond_to?(:each)
        "^#{path}"
      else
        super
      end
    end
  end
  
  
  class Address < Result
    def to_s
      "address(#{render})"
    end

    def render
      "^#{super}"
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

    def self.parse(key, value, root, env)
      if key =~ /^!([^?]+)/ then
        action = env[$1] # should resolve to action
      end
      if key =~ /\?(.+)$/ then
        cond = $1
      end
      args = value.split(SEP).map do |x|
        Result.parse(x, root, env)
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

    def inspect
      to_s
    end
    
  end

  class Template < Call
    # This class wraps enso-web functions/closures.
    # Its purpose is dual:
    # - representing calls to be rendered as URLs
    # - invoking template functions during rendering

    def self.parse(str, root, env)
      name, tail = str.split('?')
      name = name[1..-1] # strip leading /
      func = env[name] && env[name].value # NB env stores "calls"
      return if func.nil?
      return Template.new(func, []) if !tail
      # currently we depend on order of params in the url
      # so no matching of key names and formals.
      args = tail.split('&').map do |arg|
        name, value = arg.split('=')
        Result.parse(URI.unescape(value), root, env)
      end
      Template.new(func, args)
    end

    def render
      params = []
      value.formals.each_with_index do |f, i|
        arg = URI.escape(args[i].render)
        params << "#{f.name}=#{arg}"
      end
      params.empty? ? "/#{value.name}" : "/#{value.name}?#{params.join('&')}" 
    end

    # TODO: move with-args stuff here.

    def invoke(eval, env, out)
      if args then
        env = env.new
        value.formals.each_with_index do |frm, i|
          # no support for cons stuff here.
          # (maybe throw exception?)
          env[frm.name] = args[i]
        end
        eval.eval(value.body, env, out)
      else
        raise "Cannot invoke template without bound argument list"
      end
    end

    def inspect
      to_s
    end

  end
  
end

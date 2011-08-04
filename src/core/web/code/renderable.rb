
require 'core/web/code/web'

require 'htmlentities'
require 'uri'


module Web::Eval
  class Renderable
    CODER = HTMLEntities.new
  end

  class Text < Renderable
    def initialize(txt)
      @txt = txt
    end

    def value
      @txt
    end

    def render(out)
      out << CODER.encode(@txt)
    end
  end

  class Result < Renderable
    attr_reader :value, :path

    def initialize(value, path = nil)
      @value = value
      @path = path
    end
    
    def to_s
      "<#{value}, #{path}>"
    end
    
    def render(out)
      # TODO: factor out in object
      if value.respond_to?(:schema_class) then
        out << CODER.encode(path)
      else
        out << CODER.encode(value)
      end
    end
  end

  class Applicable < Renderable
    attr_reader :func, :args
    
    def initialize(func, args)
      @func = func
      @args = args
    end
  end

  class Action < Applicable
    attr_reader :cond


    def self.make(name, args)
      self.new(*parse_name_and_cond(name), parse_args(args))
    end

    def self.parse_name_and_cond(str)
      if str =~ /^!(.*)\?(.*)$/ then
        return [$1, $2]
      elsif str =~ /^!(.*)$/ then
        return [$1, nil]
      else
        raise "Action key parse error: #{str}"
      end
    end

    def self.parse_args(str)
      str.split(/:(?!@)/).map do |x|
        Value.parse(unescape(x))
      end
    end

    def self.unescape(arg)
      # URI unescaping is done by the server framework
      arg.gsub(/:@/, ':')
    end

    def initialize(func, cond, args)

      #NB: during rendering, args are Results
      #after parsing they are Values/Refs/News etc.
      #this should be unified.

      puts "ACTION INIT: #{func} #{cond} #{args}"
      super(func, args)
      @cond = cond
    end


    def redirecting?
      # TODO: make this true coding convention
      func =~ /^submit_action$/
    end

    def render(out, cond = nil)
      out << "<input type=\"hidden\" name=\"#{unparse_name(cond)}"
      out << "\" value=\"#{unparse_args}\" />"
    end

    def bind!(root, store)
      @bound_args = @args.map do |arg|
        arg.value(root, store)
      end
    end

    def execute(obj, env)
      if cond then
        obj.send(func, *@bound_args) if env[cond]
      else
        obj.send(func, *@bound_args)
      end
    end

    def to_s
      "#{func}(#{args.join(', ')})"
    end

    private

    def unparse_name(cond)
      CODER.encode("!#{func.name}#{cond && ('?' + cond)}")
    end

    def unparse_args
      # do we need func's formals here?
      args.map do |arg|
        # TODO: fix this
        s = ''
        arg.render(s)
        s
      end.join(':')
    end
    
    def escape(arg)
      CODER.encode(arg.gsub(/:/, ':@'))
    end

  end

  class Link < Applicable

    def value
      _render
    end

    def render(out)
      _render(out) do |arg|
        URI.escape(arg.to_s)
      end
    end

    private

    def _render(out = '')
      params = []
      func.formals.each_with_index do |f, i|
        arg = args[i].path || args[i].value
        param = "#{f.name}="
        if block_given? then
          params << param + (yield arg)
        else
          param << arg.to_s
        end
      end
      name = func.name
      if params.empty?
        out << name 
      else
        out << "#{name}?#{params.join('&')}"
      end
      return out
    end

  end
end


require 'core/web/code/web'

require 'htmlentities'
require 'uri'
require 'ostruct'

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

    def bind!(root, store, env)
      @bound_args = @args.map do |arg|
        # do parsing here
        # problem = if arg has a "new" key it has to be
        # converted to the old one.
        # e.g. arg can be
        #   "contact_info?item=@Item:1"
        # and this must be something like
        #   "contact_info?item=.items[id2222]

        puts "THE ARG = #{arg}"
        str = arg.value(root, store)

        if str =~ /^([a-zA-Z0-9_]+)$/ then
          # TODO: unparsing should *not* happen here...
          Link.new(env[$1].value, []).value
        elsif str =~ /^([a-zA-Z0-9_]+)\?(.+)$/
          func = env[$1].value
          args2 = $2.split('&').map do |x| 
            _, arg2 = x.split('=')
            val = Value.parse(arg2).result(root, store)
          end
          # TODO: unparsing should *not* happen here...
          Link.new(func, args2).value
        else
          Value.parse(str).value(root, store)
        end

        # OK the args in the LINK are resolved correctly,
        # if they are @news, however, the result (from .result above)
        # still contains the old @new key, so rendering fails.
        # How to find a path for a new object????!!!!
      end
    end

    def execute(obj, env)
      if cond then
        puts "COND = #{cond} BOUND ARGS = #{@bound_args}"
        @bound_args.each_with_index do |x, i|
          puts "Arg #{@args[i]} ==> #{x}"
        end
        puts "FUNC = #{func}"
        obj.send(func, *@bound_args) if env[cond]
      else
        obj.send(func, *@bound_args)
      end
    end

    def to_s
      "#{func}(#{args.join(', ')})"
    end

    #private

    def unparse_name(cond)
      CODER.encode("!#{func.name}#{cond && ('?' + cond)}")
    end


    # NOTE the use of the separator
    # and how clashes are avoided...

    SEP = "##"

    def unparse_args
      # do we need func's formals here?
      args.map do |arg|
        # TODO: fix this
        s = ''
        arg.render(s)
        s
      end.join(SEP)
    end
    
    def escape(arg)
      CODER.encode(arg.gsub(Regexp.new(Regexp.escape(SEP)), SEP + "@"))
    end

    def self.parse_args(str)
      str.split(Regexp.new(Regexp.escape(SEP) + "(?!@)")).map do |x|
        #puts "WARNING assuming, for now, that args in actions are always calls/links"
        #Link.parse(unescape(x))
        Value.parse(unescape(x))
      end
    end

    def self.unescape(arg)
      # URI unescaping is done by the server framework
      arg.gsub(Regexp.new(Regexp.escape(SEP) + "@"), SEP)
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

    def to_s
      "LINK(#{value}: #{func} applied to #{args})"
    end

#     def self.parse(str) 
#       # shit, need the environment here...
#       # to lookup func; fake it now.
#       func = OpenStruct.new
#       func.formals = []
#       args = []
#       if str =~ /^[a-zA-Z0-9_]+$/ then
#         func.name = $1
#       elsif str =~ /^([a-zA-Z0-9_]+)\?(.+)$/
#         func.name = $1
#         $2.split('&').each do |x| 
#           name, arg = x.split('=')
#           frm = OpenStruct.new
#           frm.name = name
#           puts "FRM = #{frm.name}, arg = #{arg}"
#           func.formals << frm
#           # TODO: I need the path if value parses to a ref
#           # but not otherwise...
#           v = Value.parse(arg)
#           args << Result.new(v)
#         end
#       else
#         raise "Cannot parse link #{str}"
#       end
#       Link.new(func, args)
#     end

    private

    def _render(out = '')
      params = []
      func.formals.each_with_index do |f, i|
        arg = args[i].path || args[i].value
        param = "#{f.name}="
        if block_given? then
          params << param + (yield arg)
        else
          params << param + arg.to_s
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

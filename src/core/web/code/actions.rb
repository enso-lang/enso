
require 'core/web/code/renderable'
require 'core/web/code/reference'


module Web::Eval
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

    def render(out, cond = nil)
      out << "<input type=\"hidden\" name=\"#{unparse_name(cond)}"
      out << "\" value=\"#{unparse_args}\" />"
    end

    def execute(obj, env, root, store)
      puts "ARGS: #{@args}"
      args = @args.map do |arg|
        puts "ARG: #{arg.inspect} #{arg.class}"
        x = arg.value(root, store)
        puts "ARG value: #{x} (#{x.inspect}) #{x.class}"
        x
      end
      puts "ARGS: #{args}"
      if cond then
        obj.send(func, *args) if env[cond]
      else
        obj.send(func, *args)
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
end

class Redirect < Exception
  attr_reader :link

  def initialize(link)
    @link = link
  end
end

class DefaultActions
  
  def submit_action(link)
    redirect(link)
  end

  def redirect(link) # or call
    raise Redirect.new(link)
  end
  
  def delete_action(obj, link)
    puts "OBJ to be deleted: = #{obj.inspect}"
    obj.delete!
    redirect(link)
  end

  def check_delete_action(obj)
    obj.delete!
  end

end

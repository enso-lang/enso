
require 'core/web/code/renderable'


class Action < Applicable
  def self.make(name, args)
    self.new(parse_name(name), *parse_args(args))
  end

  def self.parse_name(str)
    if str =~ /^!(.*)\?(.*)$/ then
      return $1, $2
    elsif str =~ /^!(.*)$/ then
      return $1
    else
      raise "Action key parse error: #{str}"
    end
  end

  def self.parse_args(str)
    str.split(/:(?!@)/).map do |x|
      unescape(x)
    end
  end

  def self.unescape(arg)
    # URI unescaping is done by the server framework
    arg.gsub(/:@/, ':')
  end

  def initialize(func, args, cond = nil)
    super(func, args)
    @cond = cond
  end

  def render(out, cond = nil)
    out << "<input type=\"hidden\" name=\"#{unparse_name(cond)}"
    out << "\" value=\"#{unparse_args}\" />"
  end

  def execute(obj, post)
    obj.send(name, *args) if post[cond]
  end

  private

  def unparse_name(cond)
    CODER.encode("!#{func.name}#{cond && ('?' + cond)}")
  end

  def unparse_args
    # do we need func's formals here?
    args.map do |arg|
      escape(arg.value.to_s)
    end.join(':')
  end
  
  def escape(arg)
    URI.escape(arg.gsub(/:/, ':@'))
  end

end


class Redirect
  attr_reader :link

  def initialize(link)
    @link = link
  end
end

class DefaultActions
  
  def submit_action(name, link)
    redirect(link)
  end

  def redirect(link) # or call
    raise Redirect.new(link)
  end
  
  def delete_action(obj, link)
    obj.delete!
    redirect(link)
  end

  def check_delete_action(obj)
    obj.delete!
  end

end

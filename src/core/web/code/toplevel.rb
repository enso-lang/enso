

require 'core/system/load/load'
require 'core/web/code/eval'

require 'rack'

class Stream
  attr_reader :length, :strings

  def initialize
    @strings = []
    @length = 0;
  end

  def each(&block)
    @strings.each(&block)
  end

  def <<(s)
    @strings << s
    @length += s.length
  end
end


class Toplevel
  def initialize
    @eval = EvalWeb.new(Loader.load('example.web'))
  end

  def call(env, stream = Stream.new)
    req = Rack::Request.new(env)
    name = req.path_info[1..-1]
    params = req.params
    if @eval.defines?(name) then
      @eval.eval_req(name, params, stream)
      respond(stream)
    else
      not_found(name)
    end
  end

  def not_found(name)
    [404, {
     'Content-type' => 'text/html',
     'Content-Length' => name.length.to_s
     }, [name]]
  end

  def respond(stream)
    [200, {
      'Content-Type' => 'text/html',
       # ugh
      'Content-Length' => stream.length.to_s,
     }, stream]
  end

end


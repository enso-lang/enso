

require 'core/system/load/load'
require 'core/web/code/ensoweb'

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
  def initialize(web, root, log)
    @ew = EnsoWeb.new(web, root, log)
  end

  def call(env, stream = Stream.new)
    req = Rack::Request.new(env)
    begin
      @ew.handle(req, stream)
    rescue Redirect => e
      redirect(e.link)
    rescue Exception => e
      stream << "<pre>#{e.to_s}\n"
      e.backtrace.each do |x|
        stream << "#{x}\n"
      end
      not_found(stream)
    else
      respond(stream)
    end
  end

  def not_found(msg)
    [404, {
     'Content-type' => 'text/html',
     'Content-Length' => msg.length.to_s
     }, msg]
  end

  def redirect(url)
    [301, {
       'Content-Type' => 'text/html',
       'Location' => url,
       'Content-Length' => '0'
     }, []]
  end


  def respond(stream)
    [200, {
      'Content-Type' => 'text/html',
       # ugh
      'Content-Length' => stream.length.to_s,
     }, stream]
  end


end


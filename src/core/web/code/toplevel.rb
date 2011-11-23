

require 'core/system/load/load'
require 'core/web/code/web'
require 'core/web/code/handlers'
require 'core/web/code/module'
require 'core/web/code/env'
require 'core/web/code/xhtml'

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

class Web::EnsoWeb
  include Web::Eval

  def initialize(web, root, log)
    @web_name = web
    @log = log
    @root = Loader.load(root)
    load!
  end

  def reload_if_needed!
    if last_change(@web_name) > @last_change then
      puts "------------> RELOADING!!!"
      load!
    end
  end

  def last_change(name)
    Loader.find_model(name) do |path|
      return File.stat(path).mtime
    end    
  end
    
  def load!
    @web = Loader.load!(@web_name)
    @last_change = last_change(@web_name)
    @env = Env.root(@root, DefaultActions)
    mod_eval = Mod.new(@env, @log)
    mod_eval.eval(@web)
  end

  def call(env, stream = [])
    reload_if_needed!
    req = Rack::Request.new(env)
    if req.get? then
      Get.new(req.url, req.GET, @env, @root, @log).handle(self, stream)
    elsif req.post? then
      Post.new(req.url, req.GET, @env, @root, @log, req.POST).handle(self, stream)
    end
    # do nothing otherwise.
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
      'Content-Length' => stream.join.length.to_s,
     }, stream]
  end


end


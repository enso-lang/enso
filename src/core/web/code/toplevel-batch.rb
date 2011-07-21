
require 'core/system/load/load'
require 'core/web/code/web'
require 'core/web/code/handlers'
require 'core/web/code/module'
require 'core/system/load/load'
require 'core/schema/tools/print'
require 'core/grammar/code/layout'
require 'core/schema/code/factory'
require 'core/batches/code/batchfactory'
require 'core/batches/code/batcheval'

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

class Web::EnsoBatchWeb
  include Web::Eval

  def initialize(web, schema, log)

    #extract query from web page
    @all_queries = BatchEval.batch(web, schema.root_class)

    #pre-process query immediately to get all required information from DB
    @database = "mysql://localhost/Northwind"
    @user = "root"
    @password = ""
    @schema = schema

    @log = log
    @env = {'root' => Result.new(nil, Ref.new([]))}
    mod_eval = Mod.new(@env)
    mod_eval.eval(web)

  end

  def handle(req, out)
    handler =
    handler.handle(out)
  end


  def call(env, stream = Stream.new)
    req = Rack::Request.new(env)

    pagename = req.url.split("/")[-1].split("?")[0]
    @root = BatchFactory.new(@schema, @all_queries[pagename], @database, @user, @password).root()
    @env['root'] = Result.new(@root, Ref.new([]))

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
      'Content-Length' => stream.length.to_s,
     }, stream]
  end


end


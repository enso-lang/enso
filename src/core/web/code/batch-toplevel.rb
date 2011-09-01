
require 'core/web/code/batchweb'
require 'core/web/code/handlers.rb'
require 'core/batches/code/batchfactory'
require 'core/batches/code/batcheval'
require 'core/batches/code/secureschema'


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


class BatchWeb::EnsoWeb
  include Web::Eval

  def initialize(web, schema, auth, log)

    #pre-process query immediately to get all required information from DB
    database = "mysql://localhost/Northwind"
    dbuser = "root"
    password = ""
    schema = schema

    @log = log
    @env = {'root' => Result.new(nil, Ref.new([])), 'user' => 'Bob'}
    mod_eval = Mod.new(@env)
    mod_eval.eval(web)

    @bfact = BatchFactory.new(web, schema, auth, database, dbuser, password)
  end

  def handle(req, out)
    handler =
    handler.handle(out)
  end

  def call(env, stream = Stream.new)
    req = Rack::Request.new(env)

    #get name of page to load but do not load it yet
    pagename = req.url.split("/")[-1]
    if pagename.include? "?"
      pagename = pagename.split("?")[0]
    end

    if req.get? then
      # if GET then load the require data from the DB and load the page
      root = @bfact.query(pagename, @env['user'])
      @root = root
      @env['root'] = Result.new(@root, Ref.new([]))
      res = Get.new(req.url, req.GET, @env, @root, @log).handle(self, stream)
      @root = root
      puts "@@ root after GET"
      Print.print(@env['root'].value)
      res
    elsif req.post? then
      puts "@@ root before POST"
      Print.print(@root)
      # if POST then find the required indices to use for updating based on the old root first
      @form = Form.new(req.POST)
      bind_to_db(@root, @form, {})

      @root = @bfact.query(pagename, @env['user'])
      @env['root'] = Result.new(@root, Ref.new([]))
      Post.new(req.url, req.GET, @env, @root, @log, req.POST).handle(self, stream)
    end
  end

  def bind_to_db(root, form, errors)
    store = Store.new(root._graph_id)
    Print.print(root)
    puts "@@@@@@@@@@@@@@@@@@@@@@@@@@"
    form.each do |k, v|
      puts "Trying to bind #{k.to_s} to #{v.value(nil,nil).inspect}"
      field = k.to_s.split(".")[-1]
      obj = lookup_path(k.path, root, store)
      @bfact.update(obj, field, v.value(nil,nil))
    end
    Print.print(root)
  end

  def lookup_path(path, root, store)
    *base, fld = path
    base.inject(root) do |cur, x|
      lookup(cur, x, store)
    end
  end

  def lookup(owner, path_elt, store)
    if Store.new?(path_elt.key) then
      store[path_elt.key]
    else
      owner[path_elt.key]
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

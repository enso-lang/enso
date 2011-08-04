
require 'core/web/code/batchweb'
require 'core/web/code/batch-handlers.rb'
require 'core/batches/code/batchfactory'
require 'core/batches/code/batcheval'


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

  def initialize(web, schema, log)

    #pre-process query immediately to get all required information from DB
    @database = "mysql://localhost/Northwind"
    @user = "root"
    @password = ""
    @schema = schema

    @log = log
    @env = {'root' => Result.new(nil, Ref.new([]))}
    mod_eval = Mod.new(@env)
    mod_eval.eval(web)

    @bfact = BatchFactory.new(web, @schema, @database, @user, @password)
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
      @root = @bfact.query(pagename)
      @env['root'] = Result.new(@root, Ref.new([]))
      Print.print(@root)
      res = Get.new(req.url, req.GET, @env, @root, @log).handle(self, stream)
      puts res
      res

    elsif req.post? then
      # if POST then find the required indices to use for updating based on the old root first
      @form = Form.new(req.POST)
      bind_to_db(@root, @form, {})

      @root = @bfact.query(pagename)
      @env['root'] = Result.new(@root, Ref.new([]))
      Post.new(req.url, req.GET, @env, @root, @log, req.POST).handle(self, stream)
    end
  end

  def bind_to_db(root, form, errors)
    store = Store.new(root._graph_id)
    Print.print(root)
    form.each do |k, v|
      puts "Updating #{k} (#{k.class}) to #{v.inspect} (#{v.class}/#{v.value(nil,nil).class})"
      obj = k.update(v, root, store)
      puts "updated value in:"
      Print.print(obj)
      field = k.to_s.split(".")[-1]
      puts "field = #{field} #{k.to_s}"
      @bfact.update(obj, field, v.value(nil,nil).inspect)
    end
    Print.print(root)
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
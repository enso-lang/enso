
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

module Web::Eval

  class Expr
    # overwrites the original address evaluation in expr.rb such that
    # all addresses are flattened to be directly under the root
    # eg. "Student[Tim]->Class->Teacher->salary" becomes "Teacher[Bob]->salary"
    # note: assumes that the schema used is a dbschema (ie uses 'table')
    def Address(this, env, errors)
      path = eval(this.exp, env, errors).path
      root = env['root']
      obj = lookup_path(path.path, root.value, Store.new(root.value._graph_id))
      key = ObjectKey(obj)
      field = path.to_s.split(".")[-1]

      #the path we want is: .type[key].field
      r = root.path
      r = r && r.descend_field(obj.schema_class.table)
      r = r && r.descend_collection(key)
      r = r && r.descend_field(field)
      path = r

      @log.warn("Address asked, but path is nil (val = #{path})") if path.nil?
      Result.new(path)
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
      res
    elsif req.post? then
      # if POST then find the required indices to use for updating based on the old root first
      @form = Form.new(req.POST)
      bind_to_db(@form)

      @root = @bfact.query(pagename, @env['user'])
      @env['root'] = Result.new(@root, Ref.new([]))
      Post.new(req.url, req.GET, @env, @root, @log, req.POST).handle(self, stream)
    end
  end

  def bind_to_db(form)
#    store = Store.new(root._graph_id)
    form.each do |k, v|
      k.to_s =~ /^(.*)\[(.*)\](.*)$/
      typ = $1[1..$1.length]
      key = $2
      field = $3[1..$3.length]
      @bfact.update(typ, key, field, v.value(nil,nil))
    end
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



require 'core/system/load/load'
require 'apps/web/code/web'
require 'apps/web/code/expr'
require 'apps/web/code/render'
require 'apps/web/code/module'
require 'apps/web/code/env'
require 'apps/web/code/actions'
require 'apps/web/code/form'
require 'apps/web/code/xhtml2txt'

require 'rack'

class Web::EnsoWeb
  include Web::Eval

  def initialize(web, root, log)
    @web_name = web
    @log = log
    @root = Load::load(root)
    @toplevel = Env.root(@root, DefaultActions)
    @eval = Render.new(Expr.new, log)
    load!
  end

  
  ### The interface to Rack
  def call(env)
    reload_if_needed!
    req = Rack::Request.new(env)
    if req.get? then
      get(req, @toplevel)
    elsif req.post? then
      post(req) 
    end
  end

  private

  def get(req, env, errors = {})
    call = Template.parse(req.fullpath, @root, env)
    if call then
      # self/errors are dynamic variables
      @toplevel['errors'] = Record.new(errors)
      @toplevel['self'] = call
      call.invoke(@eval, env.new, elts = [])
      render(elts)
    else
      not_found(req.fullpath)
    end
  end

  def post(req)
    form = Form.new(req.POST, @toplevel, @root)
    form.each_binding do |ref, value|
      ref.assign(value)
    end

    errors = {}
    # TODO: save/finalize to collect errors

    link = nil
    form.each_action do |action|
      link ||= action.invoke(form.env)
    end
    
    if errors.empty? then
      redirect(link.render)
    else
      get(req, form.env, errors)
    end
  end

  def render(elts)
    str = ''
    elts.each do |elt|
      XHTML2Text.render(elt, str)
    end
    respond(str)
  end

  def not_found(msg)
    response(404, msg)
  end

  def redirect(url)
    response(301, '', 'Location' => url)
  end

  def respond(str)
    response(200, str)
  end

  def response(status, str, opts = {})
    [status, {      
       'Content-Type' => 'text/html',
       'Content-Length' => str.length.to_s,
     }.update(opts), str]
  end

  def reload_if_needed!
    if last_change(@web_name) > @last_change then
      @log.info("Reloading #{@web_name}")
      load!
    end
  end

  def last_change(name)
    Loader.find_model(name) do |path|
      return File.stat(path).mtime
    end    
  end
    
  def load!
    @web = Load::load!(@web_name)
    @last_change = last_change(@web_name)
    mod_eval = Mod.new(@toplevel, @log)
    mod_eval.eval(@web)
  end
end


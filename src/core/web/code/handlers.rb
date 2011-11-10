
require 'core/web/code/expr'
require 'core/web/code/render'
require 'core/web/code/values'
require 'core/web/code/actions'
require 'core/web/code/module'
require 'core/web/code/store'
require 'core/web/code/form'


require 'core/schema/tools/print'

module Web::Eval

  class Handler

    def initialize(url, params, env, root, log)
      @url = url
      @params = params
      @env = env
      @actions = DefaultActions.new
      @root = root
      @store = Store.new(root._graph_id)
      @eval = Render.new(Expr.new(@store, log, @actions), log)
    end

    def render(func, out, params, form = {}, errors = {})
      env = {}.update(@env)

      # TODO: get rid of the side-effect in root_env
      # which just serves to have dyn. scoping for self
      # (make a param?)
      @env['self'] = Result.new(@url)

      # TODO: extract into method
      params.each do |k, v|
        puts "\t********** SETTING: #{k} to #{v}"
        env[k] = Value.parse(v).result(@root, @store)
      end

      func.run(@eval, env, out, errors)    
    end

    private

    def lookup(url)
      r = @env[route(url)]
      return r.value if r
    end

    def route(url)
      puts "URL = #{url}"
      if url =~ /\/\/[^\/]*\/([a-zA-Z][A-Za-z0-9_]*)/ then
        return $1
      end
    end
    
  end

  class Get < Handler
    def handle(http, out)
      func = lookup(@url)
      if func then
        render(func, out, @params)
        http.respond(out)
      else
        http.not_found(@url)
      end
    end
  end

  class Post < Handler

    def initialize(url, params, env, root, log, form)
      super(url, params, env, root, log)
      @form = Form.new(form)
    end

    def handle(http, out)
      errors = {}
      #puts "BEFORE BINDING"
      #Print.print(@root)

      bind(@root, @form, @store, errors)
      begin
        execute(@root, @form, @store, errors)
      rescue Web::Redirect => e
        http.redirect(e.link)
      else
        # TODO: merge @params and @form.env?
        render(lookup(@url), out, @params, @form.env, errors)
      end
    end

    private

    def bind(root, form, store, errors)
      Print.print(root)
      form.each do |k, v|
        k.update(v, root, store)
      end
    end

    def execute(root, form, store, errors)
      form.actions.each do |action|
        # first bind object-refs to their values
        action.bind!(root, store)
      end
      # only then execute
      later = []
      form.actions.each do |action|
        if action.redirecting? then
          later << action
        else
          action.execute(@actions, form.env)
        end
      end
      later.first.execute(@actions, form.env)
    end

  end
end

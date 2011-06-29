
require 'core/web/code/expr'
require 'core/web/code/render'
require 'core/web/code/reference'
require 'core/web/code/actions'
require 'core/web/code/module'
require 'core/web/code/store'
require 'core/web/code/params'



module Web::Eval

  # TODO: get rid of this
  class NoRoute < RuntimeError
    attr_reader :url
    def initialize(url)
      @url = url
    end
  end


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

    def render(out, params, form = {}, errors = {})
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

      func = lookup(@url)
      func.run(@eval, env, out, errors)    
    end

    private

    def lookup(url)
      r = @env[route(url)]
      return r.value if r
      raise "No such function: #{r}" 
    end

    def route(url)
      puts "URL = #{url}"
      if url =~ /\/\/[^\/]*\/([a-zA-Z][A-Za-z0-9_]*)/ then
        return $1
      else
        raise NoRoute.new(url)
      end
    end
    
  end

  class Get < Handler
    def handle(out)
      render(out, @params)
    end
  end

  class Post < Handler

    def initialize(url, params, env, root, log, form)
      super(url, params, env, root, log)
      puts "FORM: #{form}"
      @form = Form.new(form)
    end

    def handle(out)
      errors = {}
      bind(@root, @form, @store, errors)
      execute(@root, @form, @store, errors) # throws redirect if ok
      # TODO: merge @params and @form.env?
      render(out, @params, @form.env, errors)
    end

    private

    def bind(root, form, store, errors)
      form.each do |k, v|
        k.update(v, root, @store)
      end
    end

    def execute(root, form, store, errors)
      form.actions.each do |action|
        action.execute(@actions, form.env, root, store)
      end
    end

  end
end

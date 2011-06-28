
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
      @params = Params.new(params)
      log.debug(@params.to_s)
      @env = env
      @actions = DefaultActions.new
      @root = root
      @store = Store.new(root._graph_id)
      @eval = Render.new(Expr.new(@store, log, @actions), log)
    end

    def render(out, errors = {})
      env = {}.update(@env)

      # TODO: get rid of the side-effect in root_env
      # which just serves to have dyn. scoping for self
      # (make a param?)
      @env['self'] = Result.new(@url)
      @params.each do |k, v|
        puts "\t********** SETTING: #{k} (#{k.name}) to #{v} (#{v.value(@root, @store)})"
        env[k.name] = v.result(@root, @store) if k.var?
        #Result.new(v.value(@root, @store)) if k.var?
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
      render(out)
    end
  end

  class Post < Handler
    def handle(out)
      errors = {}
      bind(@root, @params, errors)
      execute(@params, errors) # throws redirect if ok
      # todo: don't render with the original querystring
      # just the url.
      render(out, errors)
    end

    private

    def bind(root, post, errors)
      post.each do |k, v|
        rv = v.value(root, @store)
        k.update(rv, root, @store)
      end
    end

    def execute(post, errors)
      post.actions.each do |action|
        action.execute(@actions, post)
      end
    end

  end
end

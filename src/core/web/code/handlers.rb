
require 'core/web/code/expr'
require 'core/web/code/render'
require 'core/web/code/actions'
require 'core/web/code/module'
require 'core/web/code/form'
require 'core/web/code/xhtml'

require 'core/schema/tools/print'
require 'core/grammar/code/layout'
require 'core/system/load/load'

module Web::Eval

  class Handler

    def initialize(url, params, env, root, log)
      @url = url
      @params = params
      @env = env
      @actions = DefaultActions.new
      @root = root
      @eval = Render.new(Expr.new(@store, log, @actions), log)
    end

    def render(func, out, params, form = {}, errors = {})
      env = @env.new

      # TODO: get rid of the side-effect in root_env
      # which just serves to have dyn. scoping for self
      # (make a param?)
      @env['self'] = Result.new(@url)

      # TODO: extract into method
      params.each do |k, v|
        puts "\t********** SETTING: #{k} to #{v}"
        env[k] = Result.parse(v, @root, @env)
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
        x = []
        RenderXHTML.render(out[0], x)
        #Print.print(out[0])
        #g = Loader.load('xhtml-content.grammar')
        #DisplayFormat.print(g, out[0])
        #p x
        http.respond(x)
      else
        http.not_found(@url)
      end
    end
  end

  class Post < Handler
    attr_reader :form

    def initialize(url, params, env, root, log, form)
      super(url, params, env, root, log)
      @form = Form.new(form, env, root)
    end

    def handle(http, out)
      errors = {}
      form.each_binding do |ref, value|
        ref.assign(value)
      end
      redir = nil
      form.each_action do |action|
        begin
          action.invoke(form.env)
        rescue Web::Redirect => e
          redir = e.link
        end
      end
      if redir then
        # NB: only render here for canonical paths...
        # this must be done better and less explicit
        puts "************ RENDERING the link: #{redir.render}"
        http.redirect(redir.render)
      else
        render(lookup(@url), out, @params, form.env, errors)
      end
    end


  end
end

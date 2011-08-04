
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

    def initialize(url, params, root, batchfactory, log)
      @url = url
      @params = params
      @actions = DefaultActions.new
      @log = log
      @root = root
      @bfact = batchfactory
      @env['root'] = Result.new(@root, Ref.new([]))
      @store = Store.new(@root._graph_id)
      @eval = Render.new(Expr.new(@store, @log, @actions), @log)
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

    def initialize(url, params, env, batchfactory, log, form)
      super(url, params, env, batchfactory, log)
      @form = Form.new(form)
    end

    def handle(http, out)

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

    def self.new?(key)
      key =~ /^@(.*):[0-9]+$/
      return $1
    end

    def bind_to_db(root, form, errors)
      Print.print(root)
      #sort the bindings to get the create binding on top
      creates = {}
      updates = {}
      form.each do |k, v|
        if new?(k)
          creates[k] = v
        else
          updates[k] = v
        end
      end

      creates.each do |k, v|
        puts "Creating #{k} (#{k.class}) to #{v} (#{v.class})"
      end

      updates.each do |k, v|

      end

      form.each do |k, v|

        puts "Updating #{k} (#{k.class}) to #{v} (#{v.class})"
        *base, fld = path

        puts "UPDATING: #{base.join('.')} #{fld} to #{rvalue}"
        owner = base.inject(root) do |cur, x|
          lookup(cur, x, store)
        end

        obj = k.update(v, root, store)
        Print.print(obj)
      end
      Print.print(root)
    end

    def bind(root, form, store, errors)
      Print.print(root)
      form.each do |k, v|
        puts "Updating #{k} (#{k.class}) to #{v} (#{v.class})"
        k.update(v, root, store)
      end
      Print.print(root)
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

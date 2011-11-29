
require 'core/web/code/dispatch'
require 'core/web/code/closure'
require 'core/web/code/result'
require 'core/system/load/load'

module Web::Eval

  class Mod
    include Dispatch

    PRELUDE = 'prelude'

    def initialize(env, log)
      @env = env
      @imports = {}
      @log = log
      import(PRELUDE)
    end

    def Web(this)
      this.toplevels.each do |t|
        eval(t)
      end
    end

    def Def(this)
      if @env[this.name] then
        @log.warn("Duplicate definition #{this.name}; overwriting.")
      end
      @env[this.name] = Template.new(Function.new(@env, this))
    end

    def Import(this)
      import(this.module)
    end

    private

    def import(mod)
      unless @imports[mod]
        web = Loader.load("#{mod}.web")
        @imports[mod] = web
        eval(web)
      end
    end

  end

end
